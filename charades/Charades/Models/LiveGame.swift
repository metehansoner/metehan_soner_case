import Foundation
import Observation
import SwiftUI


enum LivePhase: Equatable {


    case slate

    case countdown
    case playing

    case paused


    case roundEnd


    case teamHandoff(nextTeam: Int, nextPlayer: String?)

    case matchEnd
}


@MainActor
@Observable
final class LiveGame {


    struct Answer: Identifiable, Equatable {


        let id: String
        let card: Card
        var isCorrect: Bool


        let offset: TimeInterval

        init(card: Card, isCorrect: Bool, offset: TimeInterval) {
            self.id = UUID().uuidString
            self.card = card
            self.isCorrect = isCorrect
            self.offset = offset
        }
    }

    enum Flash: Equatable {
        case correct
        case skip
    }


    enum PauseReason: Equatable {
        case user

        case system
    }


    enum Exit: Equatable {
        case home
        case teamRematch


        case archive
    }


    let mode: GameMode
    let deckIDs: [String]


    let customCards: [Card]


    private(set) var duration: Int
    private let baseDuration: Int


    let match: TeamMatch?


    private(set) var answerInput: AnswerInput


    private(set) var playsInPortrait: Bool


    private(set) var phase: LivePhase
    private(set) var currentCard: Card?
    private(set) var answers: [Answer] = []
    private(set) var flash: Flash?
    private(set) var pauseReason: PauseReason = .user


    private(set) var reel: ReplayReel?


    private(set) var matchHasReels = false


    var isRecording: Bool { ReplayRecorder.shared.isRecording }


    private(set) var countdownValue = 3


    var sceneNumber: Int { (match?.results.count ?? soloRoundIndex) + 1 }


    var takeNumber: Int { max(match?.currentRound ?? takeIndex, 1) }


    var isSlateFull: Bool { !slateWasShown }

    private var soloRoundIndex = 0
    private var takeIndex = 1
    private var slateWasShown = false


    private(set) var remaining: Int


    private(set) var didWrapPool = false


    private(set) var handoffCountdown = 0


    var showsOrientationReminder: Bool {
        phase == .playing && answerInput == .tilt && MotionService.shared.isSilentTooLong
    }


    var score: Int { correctAnswers.count * mode.scoreMultiplier }


    var wordTimeFraction: Double? {
        guard let limit = mode.perWordLimit, let deadline = wordDeadline else { return nil }
        return min(1, max(0, (remainingExact - deadline) / limit))
    }


    private(set) var rapidRecordToBeat = 0

    var isNewRapidRecord: Bool { mode == .rapid && score > rapidRecordToBeat }

    var correctAnswers: [Answer] { answers.filter(\.isCorrect) }
    var skippedAnswers: [Answer] { answers.filter { !$0.isCorrect } }


    var isInFinalTen: Bool { phase == .playing && remaining <= 10 }


    var prefersLandscape: Bool {
        guard !playsInPortrait else { return false }
        switch phase {
        case .matchEnd: return false
        case .slate, .countdown, .playing, .paused, .roundEnd, .teamHandoff: return true
        }
    }


    let showsInputHint: Bool

    private var pool: WordPool
    private var remainingExact: TimeInterval
    private var wordDeadline: TimeInterval?
    private var lastTickAt: Date?
    private var ticker: Task<Void, Never>?
    private var flashTask: Task<Void, Never>?
    private var roundStartedAt: Date?
    private var lastWarningSecond: Int?


    private let matchID = UUID().uuidString

    private let onExit: (Exit) -> Void


    init(
        mode: GameMode,
        deckIDs: [String],
        duration: Int,
        difficulty: CardDifficultyFilter,
        answerInput: AnswerInput,
        playsInPortrait: Bool,
        roundsPlayed: Int,
        match: TeamMatch? = nil,
        customCards: [Card] = [],
        onExit: @escaping (Exit) -> Void
    ) {
        self.mode = mode
        self.deckIDs = deckIDs
        self.customCards = customCards
        self.duration = duration
        self.baseDuration = duration
        self.match = match
        self.answerInput = playsInPortrait ? .touch : answerInput
        self.playsInPortrait = playsInPortrait
        self.showsInputHint = roundsPlayed < 3
        self.onExit = onExit


        pool = customCards.isEmpty
            ? WordPool(byDeck: CardBank.shared.cardsByDeck(in: deckIDs, difficulty: difficulty))
            : WordPool(cards: customCards)

        remaining = duration
        remainingExact = TimeInterval(duration)


        phase = .slate
    }


    func beginSlate() {
        phase = .slate
        flash = nil
    }


    func finishSlate() {
        guard phase == .slate else { return }
        slateWasShown = true
        beginCountdown()
    }


    func beginCountdown(resuming: Bool = false) {
        phase = .countdown
        countdownValue = 3
        flash = nil

        if resuming {
            ReplayRecorder.shared.resumeAfterPause()
        } else {
            ReplayRecorder.shared.start(replayContext)
        }

        if answerInput == .tilt {
            MotionService.shared.beginCalibration()
        }
        Haptics.prepareImpact()
        Haptics.prepareNotification()

        startTicker(interval: 1) { [weak self] in
            guard let self else { return }
            countdownValue -= 1
            if countdownValue <= 0 {
                startPlaying()
            } else {
                Haptics.countdownTick()
                SoundService.countdownTick()
            }
        }
        Haptics.countdownTick()
        SoundService.countdownTick()
    }


    func shortenCountdown() {
        guard phase == .countdown, countdownValue > 1 else { return }
        countdownValue = 1
        startTicker(interval: 1) { [weak self] in
            self?.startPlaying()
        }
    }

    private func startPlaying() {
        phase = .playing
        roundStartedAt = Date()
        lastWarningSecond = nil

        if answerInput == .tilt {
            MotionService.shared.startDetecting { [weak self] trigger in
                self?.answer(isCorrect: trigger == .correct)
            }
        }

        advanceCard()
        startRoundClock()

        SoundService.startProjector()
        logRoundStart()

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-AutoScore") {
            startDebugAutoScore()
        }
        #endif
    }

    private func logRoundStart() {
        Analytics.roundStart(mode: mode.id, deckIDs: deckIDs, duration: duration)


        if !SubscriptionStore.shared.isPremium,
           let daily = DeckCatalog.dailyFreeDeckID(),
           deckIDs.contains(daily) {
            Analytics.dailyFreeDeckPlay(deckID: daily)
        }
    }

    #if DEBUG


    private func startDebugAutoScore() {
        Task { [weak self] in
            var flip = false
            var produced = 0
            while !Task.isCancelled, produced < 8 {
                try? await Task.sleep(for: .milliseconds(700))
                guard let self, phase == .playing, flash == nil else { continue }
                flip.toggle()
                answer(isCorrect: flip)
                produced += 1
            }
        }
    }
    #endif


    func answer(isCorrect: Bool) {
        guard phase == .playing, flash == nil, let card = currentCard else { return }

        let offset = roundStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        answers.append(Answer(card: card, isCorrect: isCorrect, offset: offset))

        ReplayRecorder.shared.mark(
            word: card.text(for: LocalizationManager.shared.localeCode),
            key: card.k,
            isCorrect: isCorrect
        )

        if isCorrect {
            Haptics.answerCorrect()
            SoundService.correct()
        } else {
            Haptics.answerSkip()
            SoundService.skip()
        }

        flash = isCorrect ? .correct : .skip


        MotionService.shared.suspend()

        flashTask?.cancel()
        flashTask = Task { [weak self] in

            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled, let self, phase == .playing else { return }
            flash = nil
            advanceCard()
            MotionService.shared.resume()
        }
    }

    private func advanceCard() {
        currentCard = pool.next()
        didWrapPool = pool.didWrap

        if let limit = mode.perWordLimit {
            wordDeadline = remainingExact - limit
        }


        if currentCard == nil {
            endRound()
            return
        }

        SoundService.cardSlide()
    }


    private func startRoundClock() {
        lastTickAt = Date()
        startTicker(interval: 0.1) { [weak self] in
            self?.tick()
        }
    }

    private func tick() {
        guard phase == .playing else { return }

        let now = Date()
        let elapsed = now.timeIntervalSince(lastTickAt ?? now)
        lastTickAt = now
        remainingExact = max(0, remainingExact - elapsed)

        let seconds = Int(remainingExact.rounded(.up))
        if seconds != remaining {
            remaining = seconds

            if seconds <= 10, seconds > 0, lastWarningSecond != seconds {
                lastWarningSecond = seconds
                Haptics.warningTick()
                SoundService.warningTick()
            }
        }


        if let deadline = wordDeadline, remainingExact <= deadline, flash == nil {
            answer(isCorrect: false)
            return
        }

        if remainingExact <= 0 {
            Haptics.timeUp()
            SoundService.timeUp()
            endRound()
        }
    }


    func lockTriggersForPauseGesture() {
        MotionService.shared.lockForPauseGesture()
    }

    func pause(reason: PauseReason) {


        guard phase == .playing || phase == .countdown || phase == .slate else { return }
        pauseReason = reason
        phase = .paused
        flash = nil
        flashTask?.cancel()
        stopTicker()
        MotionService.shared.suspend()
        SoundService.stopProjector()


        if reason == .system {
            ReplayRecorder.shared.interrupt()
        } else {
            ReplayRecorder.shared.pauseForUser()
        }
    }


    func resume() {
        guard phase == .paused else { return }
        beginCountdown(resuming: true)
    }


    func restartRound() {
        takeIndex += 1
        resetRound()
        beginSlate()
    }

    private func resetRound() {
        stopTicker()
        flashTask?.cancel()
        flash = nil

        ReplayRecorder.shared.discard()
        reel = nil
        answers.removeAll()
        pool.reset()
        didWrapPool = false
        currentCard = nil
        remaining = duration
        remainingExact = TimeInterval(duration)
        wordDeadline = nil
    }


    func exit() {
        leave(.home)
    }


    func rematch() {
        leave(.teamRematch)
    }

    func openArchive() {
        leave(.archive)
    }

    private func leave(_ route: Exit) {
        commitRapidScore()
        teardown()
        onExit(route)
    }


    private func endRound() {
        stopTicker()
        flashTask?.cancel()
        flash = nil
        phase = .roundEnd
        rapidRecordToBeat = AppSettingsStore.shared.rapidHighScore

        MotionService.shared.stop()
        SoundService.stopProjector()


        Task { [weak self] in
            let reel = await ReplayRecorder.shared.finish()
            self?.reel = reel
            if reel != nil { self?.matchHasReels = true }
        }


        AppSettingsStore.shared.recordRoundPlayed()


        Analytics.roundComplete(
            mode: mode.id,
            deckIDs: deckIDs,
            duration: duration,
            correct: correctAnswers.count,
            skipped: skippedAnswers.count
        )

        #if DEBUG


        if match != nil, ProcessInfo.processInfo.arguments.contains("-AutoScore") {
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                self?.finishTeamTurn()
            }
        }
        #endif
    }


    func toggleAnswer(_ id: String) {
        guard let index = answers.firstIndex(where: { $0.id == id }) else { return }
        answers[index].isCorrect.toggle()
        Haptics.selection()


        guard var reel else { return }
        let cardKey = answers[index].card.k
        let ordinal = answers.prefix(index + 1).filter { $0.card.k == cardKey }.count - 1
        let markIndices = reel.marks.indices.filter { reel.marks[$0].key == cardKey }
        if ordinal < markIndices.count {
            reel.marks[markIndices[ordinal]].isCorrect = answers[index].isCorrect
            self.reel = reel
            ReplayStore.save(reel)
        }
    }


    func deleteReel() {
        guard let reel else { return }
        Analytics.replayDelete()
        ReplayStore.delete(id: reel.id)
        self.reel = nil
    }


    func playAgain() {
        commitRapidScore()


        soloRoundIndex += 1
        takeIndex = 1
        resetRound()
        beginSlate()
    }


    private func commitRapidScore() {
        guard phase == .roundEnd, mode == .rapid else { return }
        AppSettingsStore.shared.recordRapidScore(score)
    }


    var isFinalTeamTurn: Bool {
        guard let match else { return false }
        return !match.isSuddenDeath && match.completedTurns + 1 >= match.totalTurns
    }


    func finishTeamTurn() {
        guard phase == .roundEnd, let match else { return }

        switch match.finishTurn(
            correct: correctAnswers.count,
            skipped: skippedAnswers.count,
            points: score
        ) {
        case .turn(let team, let player):
            duration = match.isSuddenDeath ? TeamMatch.suddenDeathDuration : baseDuration
            phase = .teamHandoff(nextTeam: team, nextPlayer: player)
            startHandoffCountdown()

        case .matchEnd:
            teardown()
            phase = .matchEnd
            Haptics.matchWon()
            SoundService.winFanfare()
        }
    }


    func beginTeamTurn() {
        guard case .teamHandoff = phase else { return }
        takeIndex = 1
        resetRound()
        beginSlate()
    }

    private func startHandoffCountdown(seconds: Int = 5) {
        handoffCountdown = seconds
        startTicker(interval: 1) { [weak self] in
            guard let self, case .teamHandoff = phase else { return }
            handoffCountdown -= 1
            if handoffCountdown <= 0 { beginTeamTurn() }
        }
    }


    func handleSceneInactive() {


        if case .teamHandoff = phase {
            stopTicker()
            return
        }
        pause(reason: .system)
    }

    func handleSceneActive() {
        guard case .teamHandoff = phase, handoffCountdown > 0 else { return }
        startHandoffCountdown(seconds: handoffCountdown)
    }

    private func teardown() {
        stopTicker()
        flashTask?.cancel()
        MotionService.shared.stop()
        SoundService.stopProjector()


        ReplayRecorder.shared.discard()
    }


    private var replayContext: ReplayRecorder.Context {
        ReplayRecorder.Context(
            matchID: matchID,
            sceneIndex: (match?.results.count ?? 0) + 1,
            deckIDs: customCards.isEmpty ? deckIDs : [],
            modeID: mode.id,


            playerName: match?.currentPlayer
        )
    }


    private func startTicker(interval: TimeInterval, _ body: @escaping () -> Void) {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled, self != nil else { return }
                body()
            }
        }
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }
}

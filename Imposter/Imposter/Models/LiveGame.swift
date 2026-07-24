import SwiftUI

struct DrawStroke: Identifiable, Equatable {
    let id: UUID
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat

    init(id: UUID = UUID(), points: [CGPoint] = [], color: Color, lineWidth: CGFloat = 4) {
        self.id = id
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
    }
}

enum LivePhase: Equatable {
    case passPhone(Int)
    case reveal(Int)
    case ready
    case discussion
    case drawing
    case voting
    case results
}

enum GameOutcome: Equatable {
    case crewWins
    case imposterWinsHidden
    case twistNoImposter
    case twistAllImposters
}

enum PlayerReveal: Hashable {
    case word(String)
    case impostor
    case blank
}

/// Active mystery rule for this round (hidden from players until results).
enum MysteryTwist: Equatable {
    case none
    case noImposter
    case allImposters
    case decoy(playerID: UUID)
    case blank(playerID: UUID)
}

struct AssignedPlayer: Identifiable, Hashable {
    let id: UUID
    let name: String
    /// True impostor for win checks (may differ from what the card shows).
    let isImposter: Bool
    let avatarIndex: Int
    let reveal: PlayerReveal

    var avatarImageName: String {
        String(format: "player_%02d", avatarIndex)
    }

    var accent: Color {
        Self.accents[(avatarIndex - 1) % Self.accents.count]
    }

    static let accents: [Color] = [
        Color(hex: 0x1A6FE8), Color(hex: 0x12C4C8), Color(hex: 0x0B3D4A),
        Color(hex: 0x2B6CFF), Color(hex: 0xFFE566), Color(hex: 0xF08A3A),
        Color(hex: 0x7B5CFF), Color(hex: 0x00B894), Color(hex: 0x123A7A),
        Color(hex: 0xFF6B9D), Color(hex: 0x00E5FF), Color(hex: 0xE17055),
        Color(hex: 0x6C5CE7), Color(hex: 0x81ECEC), Color(hex: 0x0984E3)
    ]
}

@Observable
final class LiveGame {
    let players: [AssignedPlayer]
    let secretWord: String
    let hint: String
    let hintsEnabled: Bool
    let roundDurationSeconds: Int
    let mode: GameMode
    let mysteryTwistEnabled: Bool
    let activeTwist: MysteryTwist
    let decoyWord: String?

    var phase: LivePhase
    var remainingSeconds: Int
    var isPaused = false
    var votes: [UUID: UUID] = [:]
    var outcome: GameOutcome?

    // Drawing
    var strokes: [DrawStroke] = []
    var currentStroke: DrawStroke?
    var selectedColor: Color = .black
    var drawerIndex = 0
    var showDrawerOverlay = true
    var showExitConfirm = false

    static let palette: [Color] = [
        .black,
        Color(hex: 0xFF6B9D),
        Color(hex: 0xF08A3A),
        Color(hex: 0xFFE566),
        Color(hex: 0x00B894),
        Color(hex: 0x00E5FF),
        Color(hex: 0x2B6CFF),
        Color(hex: 0x7B5CFF)
    ]

    init(from session: GameSession) {
        let named = session.namedPlayers
        let locale = LocalizationManager.shared.localeCode
        let entry = WordBank.randomWord(categoryIDs: session.selectedCategoryIDs, locale: locale)
        secretWord = entry.word
        hint = entry.hint
        hintsEnabled = session.imposterHintsEnabled
        roundDurationSeconds = session.roundDurationSeconds
        remainingSeconds = session.roundDurationSeconds
        mode = session.selectedMode
        mysteryTwistEnabled = session.mysteryTwistEnabled
        phase = .passPhone(0)

        let impostorCount = min(session.imposterCount, max(1, named.count - 2))
        let shuffled = named.shuffled()
        let baseImpostorIDs = Set(shuffled.prefix(impostorCount).map(\.id))

        let twistPick: MysteryTwist
        var decoy: String?
        if session.mysteryTwistEnabled, Double.random(in: 0...1) < 0.7, named.count >= 3 {
            let kinds = ["noImposter", "allImposters", "decoy", "blank"]
            switch kinds.randomElement()! {
            case "noImposter":
                twistPick = .noImposter
            case "allImposters":
                twistPick = .allImposters
            case "decoy":
                let crew = named.filter { !baseImpostorIDs.contains($0.id) }
                let target = (crew.isEmpty ? named : crew).randomElement()!.id
                decoy = WordBank.decoyWord(
                    categoryIDs: session.selectedCategoryIDs,
                    excluding: entry.word,
                    locale: locale
                ).word
                twistPick = .decoy(playerID: target)
            default:
                let crew = named.filter { !baseImpostorIDs.contains($0.id) }
                let target = (crew.isEmpty ? named : crew).randomElement()!.id
                twistPick = .blank(playerID: target)
            }
        } else {
            twistPick = .none
        }
        activeTwist = twistPick
        decoyWord = decoy

        players = named.enumerated().map { index, player in
            let reveal: PlayerReveal
            let isImposter: Bool

            switch twistPick {
            case .noImposter:
                isImposter = false
                reveal = .word(entry.word)
            case .allImposters:
                isImposter = true
                reveal = .impostor
            case .decoy(let decoyID):
                isImposter = baseImpostorIDs.contains(player.id)
                if player.id == decoyID, let decoy {
                    reveal = .word(decoy)
                } else if isImposter {
                    reveal = .impostor
                } else {
                    reveal = .word(entry.word)
                }
            case .blank(let blankID):
                isImposter = baseImpostorIDs.contains(player.id)
                if player.id == blankID {
                    reveal = .blank
                } else if isImposter {
                    reveal = .impostor
                } else {
                    reveal = .word(entry.word)
                }
            case .none:
                isImposter = baseImpostorIDs.contains(player.id)
                reveal = isImposter ? .impostor : .word(entry.word)
            }

            return AssignedPlayer(
                id: player.id,
                name: player.name,
                isImposter: isImposter,
                avatarIndex: (index % 15) + 1,
                reveal: reveal
            )
        }
    }

    var impostors: [AssignedPlayer] { players.filter(\.isImposter) }

    var blankPlayer: AssignedPlayer? {
        players.first { if case .blank = $0.reveal { return true }; return false }
    }

    var decoyPlayer: AssignedPlayer? {
        guard case .decoy(let id) = activeTwist else { return nil }
        return players.first { $0.id == id }
    }

    var currentDrawer: AssignedPlayer? {
        player(at: drawerIndex)
    }

    func player(at index: Int) -> AssignedPlayer? {
        guard players.indices.contains(index) else { return nil }
        return players[index]
    }

    func advanceAfterReveal() {
        guard case .reveal(let index) = phase else { return }
        let next = index + 1
        if next < players.count {
            phase = .passPhone(next)
        } else {
            phase = .ready
        }
    }

    func startRound() {
        remainingSeconds = roundDurationSeconds
        isPaused = false
        if mode == .drawing {
            drawerIndex = 0
            showDrawerOverlay = true
            strokes = []
            currentStroke = nil
            phase = .drawing
        } else {
            phase = .discussion
        }
        Haptics.medium()
    }

    func tick() {
        guard !isPaused, remainingSeconds > 0 else { return }
        guard phase == .discussion || phase == .drawing else { return }
        remainingSeconds -= 1
        if remainingSeconds == 0 {
            Haptics.heavy()
            isPaused = true
        } else if remainingSeconds <= 10 {
            Haptics.light()
        }
    }

    func beginStroke(at point: CGPoint) {
        guard !isPaused, !showDrawerOverlay, phase == .drawing else { return }
        currentStroke = DrawStroke(points: [point], color: selectedColor)
    }

    func appendStroke(point: CGPoint) {
        guard var stroke = currentStroke else { return }
        stroke.points.append(point)
        currentStroke = stroke
    }

    func endStroke() {
        guard let stroke = currentStroke, stroke.points.count > 1 else {
            currentStroke = nil
            return
        }
        strokes.append(stroke)
        currentStroke = nil
        Haptics.light()
    }

    func undoStroke() {
        guard !strokes.isEmpty else { return }
        strokes.removeLast()
        Haptics.selection()
    }

    func clearCanvas() {
        strokes.removeAll()
        currentStroke = nil
        Haptics.warning()
    }

    func passToNextDrawer() {
        drawerIndex = (drawerIndex + 1) % players.count
        showDrawerOverlay = true
        Haptics.medium()
    }

    func dismissDrawerOverlay() {
        showDrawerOverlay = false
        Haptics.light()
    }

    func castVote(voter: UUID, target: UUID) {
        votes[voter] = target
        Haptics.selection()
    }

    func submitVotes() {
        switch activeTwist {
        case .noImposter:
            outcome = .twistNoImposter
            Haptics.warning()
        case .allImposters:
            outcome = .twistAllImposters
            Haptics.warning()
        case .none, .decoy, .blank:
            let tallies = Dictionary(grouping: votes.values, by: { $0 }).mapValues(\.count)
            let maxVotes = tallies.values.max() ?? 0
            let leaders = tallies.filter { $0.value == maxVotes }.map(\.key)

            if leaders.count == 1,
               let accused = players.first(where: { $0.id == leaders[0] }),
               accused.isImposter {
                outcome = .crewWins
                Haptics.success()
            } else {
                outcome = .imposterWinsHidden
                Haptics.warning()
            }
        }
        phase = .results
    }
}

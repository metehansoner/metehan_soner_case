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
}

enum PlayerReveal: Hashable {
    case word(String)
    case impostor
}

struct AssignedPlayer: Identifiable, Hashable {
    let id: UUID
    let name: String
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
        Color(hex: 0x2B7BFF), // vivid blue
        Color(hex: 0xFF4D8D), // hot pink
        Color(hex: 0xFF9F1A), // bright orange
        Color(hex: 0x00E5A8), // mint
        Color(hex: 0xFFE566), // sunny yellow
        Color(hex: 0x7B5CFF), // violet
        Color(hex: 0x00D4FF), // electric cyan
        Color(hex: 0xFF5A5A), // coral red
        Color(hex: 0x3DFFB0), // neon green
        Color(hex: 0xFF6BCB), // magenta
        Color(hex: 0x4D9FFF), // sky blue
        Color(hex: 0xFFB347), // peach
        Color(hex: 0xA78BFF), // soft purple
        Color(hex: 0x2EE6D6), // turquoise
        Color(hex: 0xFF7A59)  // tangerine
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
        phase = .reveal(0)

        let impostorCount = min(session.imposterCount, max(1, named.count - 2))
        let shuffled = named.shuffled()
        let impostorIDs = Set(shuffled.prefix(impostorCount).map(\.id))

        players = named.enumerated().map { index, player in
            let isImposter = impostorIDs.contains(player.id)
            return AssignedPlayer(
                id: player.id,
                name: player.name,
                isImposter: isImposter,
                avatarIndex: (index % 15) + 1,
                reveal: isImposter ? .impostor : .word(entry.word)
            )
        }
    }

    var impostors: [AssignedPlayer] { players.filter(\.isImposter) }

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
            phase = .reveal(next)
        } else {
            startRound()
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
        phase = .results
    }
}

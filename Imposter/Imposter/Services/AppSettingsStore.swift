import Foundation

enum GameMode: String, Codable, CaseIterable, Identifiable {
    case classic
    case chain
    case doubleAgent
    case emoji
    case rapid
    case drawing

    var id: String { rawValue }

    /// Display order on the home hub.
    static let hubOrder: [GameMode] = [.classic, .chain, .doubleAgent, .emoji, .rapid, .drawing]

    /// These modes reuse the guided clue-round → discussion → voting loop.
    var usesClueLoop: Bool { self != .drawing }

    /// Impostor sees a plausible decoy word instead of the IMPOSTOR card.
    var usesDecoyWord: Bool { self == .doubleAgent }

    /// Guided clue round runs a short per-player countdown that auto-advances.
    var isRapid: Bool { self == .rapid }

    var titleKey: String { "mode.\(rawValue).title" }
    var subtitleKey: String { "mode.\(rawValue).subtitle" }
    /// Instruction shown during the clue round for this mode.
    var clueInstructionKey: String { "mode.\(rawValue).clue" }

    var iconName: String {
        switch self {
        case .classic: return "person.3.fill"
        case .chain: return "link"
        case .doubleAgent: return "person.fill.questionmark"
        case .emoji: return "face.smiling.fill"
        case .rapid: return "bolt.fill"
        case .drawing: return "scribble.variable"
        }
    }

    /// 3D clay glass icon asset in Assets.xcassets.
    var iconImageName: String {
        switch self {
        case .classic: return "mode_icon_classic"
        case .chain: return "mode_icon_chain"
        case .doubleAgent: return "mode_icon_doubleAgent"
        case .emoji: return "mode_icon_emoji"
        case .rapid: return "mode_icon_rapid"
        case .drawing: return "mode_icon_drawing"
        }
    }

    var usesGradientCard: Bool {
        self == .doubleAgent || self == .rapid
    }
}

enum RapidRoundLimits {
    static let secondsPerTurn = 12
}

@Observable
final class AppSettingsStore {
    static let shared = AppSettingsStore()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let onboardingDone = "onboardingDone"
        static let hapticsEnabled = "hapticsEnabled"
        static let notificationsEnabled = "notificationsEnabled"
        static let notificationPermissionPrompted = "notificationPermissionPrompted"
        static let awaitingSystemNotificationEnable = "awaitingSystemNotificationEnable"
        static let languageOverride = "languageOverride"
        static let userId = "userId"
        static let lastGameMode = "lastGameMode"
    }

    var onboardingDone: Bool {
        didSet { defaults.set(onboardingDone, forKey: Key.onboardingDone) }
    }

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Key.hapticsEnabled) }
    }

    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Key.notificationsEnabled) }
    }

    var notificationPermissionPrompted: Bool {
        didSet { defaults.set(notificationPermissionPrompted, forKey: Key.notificationPermissionPrompted) }
    }

    var awaitingSystemNotificationEnable: Bool {
        didSet { defaults.set(awaitingSystemNotificationEnable, forKey: Key.awaitingSystemNotificationEnable) }
    }

    var languageOverride: String? {
        didSet {
            if let languageOverride {
                defaults.set(languageOverride, forKey: Key.languageOverride)
            } else {
                defaults.removeObject(forKey: Key.languageOverride)
            }
        }
    }

    var lastGameMode: GameMode {
        didSet { defaults.set(lastGameMode.rawValue, forKey: Key.lastGameMode) }
    }

    let userId: String

    private init() {
        onboardingDone = defaults.bool(forKey: Key.onboardingDone)
        if defaults.object(forKey: Key.hapticsEnabled) == nil {
            hapticsEnabled = true
        } else {
            hapticsEnabled = defaults.bool(forKey: Key.hapticsEnabled)
        }
        if defaults.object(forKey: Key.notificationsEnabled) == nil {
            notificationsEnabled = false
        } else {
            notificationsEnabled = defaults.bool(forKey: Key.notificationsEnabled)
        }
        notificationPermissionPrompted = defaults.bool(forKey: Key.notificationPermissionPrompted)
        awaitingSystemNotificationEnable = defaults.bool(forKey: Key.awaitingSystemNotificationEnable)
        languageOverride = defaults.string(forKey: Key.languageOverride)
        if let raw = defaults.string(forKey: Key.lastGameMode),
           let mode = GameMode(rawValue: raw) {
            lastGameMode = mode
        } else {
            lastGameMode = .classic
        }
        if let existing = defaults.string(forKey: Key.userId) {
            userId = existing
        } else {
            let id = UUID().uuidString
            defaults.set(id, forKey: Key.userId)
            userId = id
        }
    }
}

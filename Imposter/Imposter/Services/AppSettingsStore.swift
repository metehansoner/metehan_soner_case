import Foundation

enum GameMode: String, Codable, CaseIterable, Identifiable {
    case classic
    case drawing

    var id: String { rawValue }
}

@Observable
final class AppSettingsStore {
    static let shared = AppSettingsStore()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let onboardingDone = "onboardingDone"
        static let hapticsEnabled = "hapticsEnabled"
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

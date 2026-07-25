import Foundation
import SwiftUI

@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()

    /// Order matches the in-app language list.
    static let supportedLocales = [
        "tr", "de", "ar", "be", "da",
        "id", "fil", "fi", "fr",
        "nl", "hr", "ca", "pl", "ms",
        "nb", "pt", "ro", "ru",
        "uk", "el", "cs", "en",
        "es", "sv", "it"
    ]

    /// Maps OS / legacy language tags onto our JSON file codes.
    private static let localeAliases: [String: String] = [
        "tl": "fil",
        "fil": "fil",
        "no": "nb",
        "nb": "nb",
        "nn": "nb",
        "in": "id",
        "id": "id"
    ]

    private(set) var localeCode: String
    private var strings: [String: String] = [:]

    private init() {
        localeCode = Self.resolveInitialLocale()
        load(locale: localeCode)
    }

    func t(_ key: String, _ args: [String: String] = [:]) -> String {
        _ = localeCode
        var value = strings[key] ?? LocalizationManager.sharedFallback[key] ?? key
        for (placeholder, replacement) in args {
            value = value.replacingOccurrences(of: "{\(placeholder)}", with: replacement)
        }
        return value
    }

    /// Display name for a locale from its own JSON `meta.languageName`, else nil.
    static func languageDisplayName(_ code: String) -> String? {
        loadJSON(named: code)?["meta.languageName"]
    }

    func setLanguage(_ code: String) {
        guard Self.supportedLocales.contains(code) else { return }
        localeCode = code
        AppSettingsStore.shared.languageOverride = code
        load(locale: code)
    }

    private func load(locale: String) {
        if let dict = Self.loadJSON(named: locale) {
            strings = dict
            return
        }
        strings = Self.loadJSON(named: "en") ?? Self.sharedFallback
    }

    private static func resolveInitialLocale() -> String {
        if let override = AppSettingsStore.shared.languageOverride,
           supportedLocales.contains(override) {
            return override
        }
        for preferred in Locale.preferredLanguages {
            if let matched = matchSupportedLocale(preferred) {
                return matched
            }
        }
        return "en"
    }

    private static func matchSupportedLocale(_ preferred: String) -> String? {
        let lowered = preferred.lowercased()
        let primary = String(lowered.split(separator: "-").first ?? Substring(lowered))

        if let aliased = localeAliases[primary], supportedLocales.contains(aliased) {
            return aliased
        }
        if supportedLocales.contains(primary) {
            return primary
        }
        // e.g. "pt-BR" already handled via primary "pt"
        return nil
    }

    private static func loadJSON(named name: String) -> [String: String]? {
        let url =
            Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Resources/Localization")
            ?? Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Localization")
            ?? Bundle.main.url(forResource: name, withExtension: "json")
        guard let url,
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return nil }
        return dict
    }

    /// Minimal English fallback if JSON missing from bundle.
    private static let sharedFallback: [String: String] = [
        "app.name": "Imposter Party",
        "common.continue": "Continue",
        "common.next": "Next",
        "common.back": "Back",
        "common.close": "Close",
        "common.play": "PLAY",
        "players.title": "Add players",
        "players.placeholder": "Enter player {n}'s name",
        "players.add": "Add player",
        "players.minHint": "At least 3 players to start",
        "players.maxHint": "Maximum 15 players",
        "onboarding.1.title": "Instant fun everywhere!",
        "onboarding.1.body": "Game night, road trip, even a weird first date — Imposter Party breaks the ice and starts the fun.",
        "onboarding.1.cta": "I'm in!",
        "onboarding.2.title": "Who's faking it?",
        "onboarding.2.body": "One of you is lying. The rest know the word. Can you find the imposter before it's too late?",
        "onboarding.2.cta": "Got it",
        "onboarding.3.title": "Speak smart. Guess well.",
        "onboarding.3.body": "Describe the secret word without saying it. Careful — the imposter is listening and trying to blend in.",
        "onboarding.3.cta": "Let's play!",
        "home.classicTitle": "Classic Imposter",
        "home.drawingTitle": "Drawing mode"
    ]
}

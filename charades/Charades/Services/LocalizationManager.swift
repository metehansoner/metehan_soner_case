import Foundation
import Observation

/// 06-ayarlar-ve-lokalizasyon.md §2. `Imposter/Services/LocalizationManager.swift`
/// yapısı taşındı; dil sheet'i, 25 dilin JSON'ları ve RTL geçişi P9'da geliyor.
@MainActor
@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()

    /// Uygulama içi dil listesindeki sıra.
    static let supportedLocales = [
        "tr", "de", "ar", "be", "da",
        "id", "fil", "fi", "fr",
        "nl", "hr", "ca", "pl", "ms",
        "nb", "pt", "ro", "ru",
        "uk", "el", "cs", "en",
        "es", "sv", "it",
    ]

    /// İşletim sisteminin verdiği eski/alternatif etiketleri JSON dosya kodlarına eşler.
    private static let localeAliases: [String: String] = [
        "tl": "fil",
        "fil": "fil",
        "no": "nb",
        "nb": "nb",
        "nn": "nb",
        "in": "id",
        "id": "id",
    ]

    private(set) var localeCode: String
    private var strings: [String: String] = [:]

    private init() {
        localeCode = Self.resolveInitialLocale()
        load(locale: localeCode)
    }

    func t(_ key: String, _ args: [String: String] = [:]) -> String {
        _ = localeCode
        var value = strings[key] ?? Self.loadJSON(named: "en")?[key] ?? key
        for (placeholder, replacement) in args {
            value = value.replacingOccurrences(of: "{\(placeholder)}", with: replacement)
        }
        return value
    }

    /// Dilin kendi JSON'undaki `meta.languageName` değeri.
    static func languageDisplayName(_ code: String) -> String? {
        loadJSON(named: code)?["meta.languageName"]
    }

    func setLanguage(_ code: String) {
        guard Self.supportedLocales.contains(code) else { return }
        localeCode = code
        AppSettingsStore.shared.languageOverride = code
        load(locale: code)
    }

    /// Yeni eklenmiş bir anahtar bir dilde henüz çevrilmemişse ham anahtar adı
    /// görünmesin diye taban her zaman İngilizce.
    private func load(locale: String) {
        let english = Self.loadJSON(named: "en") ?? [:]
        if locale == "en" {
            strings = english
            return
        }
        if let dict = Self.loadJSON(named: locale) {
            strings = english.merging(dict) { _, localized in localized }
            return
        }
        strings = english
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
}

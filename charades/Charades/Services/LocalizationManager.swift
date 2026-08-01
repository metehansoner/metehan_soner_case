import Foundation
import Observation
import SwiftUI

/// 06-ayarlar-ve-lokalizasyon.md §2. `Imposter/Services/LocalizationManager.swift`
/// yapısı taşındı: custom JSON, çünkü dil değişimi **restart'sız** olmalı
/// (`.xcstrings` bunun için `Bundle` swizzling istiyor) ve kelime verisi zaten
/// aynı çok-dilli JSON şemasında.
@MainActor
@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()

    /// §06 §2: uygulama içi dil listesindeki sıra. İngilizce ve Türkçe başta,
    /// gerisi kendi adlarının alfabetik sırasında.
    static let supportedLocales = [
        "en", "tr", "ar", "be", "ca",
        "cs", "da", "de", "el", "es",
        "fi", "fil", "fr", "hr", "id",
        "it", "ms", "nb", "nl", "pl",
        "pt", "ro", "ru", "sv", "uk",
    ]

    /// §06 §2: işletim sistemi eski/alternatif etiketler döndürebiliyor.
    /// Buradan geçmeyen her dil (`zh-*`, `ja`, `ko`, `th`, `hi`, `he`/`iw`)
    /// İngilizce'ye düşüyor.
    private static let localeAliases: [String: String] = [
        "tl": "fil",
        "no": "nb",
        "nn": "nb",
        "in": "id",
        "iw": "en",
        "he": "en",
    ]

    /// §06 §2 RTL: Arapça tek sağdan-sola dilimiz.
    static let rightToLeftLocales: Set<String> = ["ar"]

    private(set) var localeCode: String
    private var strings: [String: String] = [:]

    /// Layout yönü tek yerden okunuyor; çağrı yerlerinde dil kontrolü yok.
    var layoutDirection: LayoutDirection {
        Self.rightToLeftLocales.contains(localeCode) ? .rightToLeft : .leftToRight
    }

    private init() {
        localeCode = Self.resolveInitialLocale()
        load(locale: localeCode)
    }

    func t(_ key: String, _ args: [String: String] = [:]) -> String {
        // `localeCode` okunuyor ki `@Observable` bu çağrıyı dile bağlasın:
        // dil değişince metin kullanan her görünüm yeniden çiziliyor.
        _ = localeCode
        return substitute(strings[key] ?? Self.loadJSON(named: "en")?[key] ?? key, args)
    }

    /// §06 §2: çoğul anahtarlar `key.one` / `key.other` çifti, Slav dilleri ve
    /// Arapça için ayrıca `key.few`. Sayı her zaman `{count}` yerine geçiyor.
    ///
    /// Eksik kategori sessizce `.other`a düşüyor: `id`/`ms` gibi çoğulu olmayan
    /// diller tek biçim yazıyor ve `.one` araması onları İngilizce'ye
    /// düşürmemeli.
    func t(_ key: String, count: Int, _ args: [String: String] = [:]) -> String {
        _ = localeCode
        let merged = args.merging(["count": "\(count)"]) { current, _ in current }
        let category = Self.pluralCategory(count, locale: localeCode)
        let english = Self.loadJSON(named: "en")

        for candidate in ["\(key).\(category.rawValue)", "\(key).other", key] {
            if let value = strings[candidate] ?? english?[candidate] {
                return substitute(value, merged)
            }
        }
        return key
    }

    private func substitute(_ value: String, _ args: [String: String]) -> String {
        guard !args.isEmpty else { return value }
        var result = value
        for (placeholder, replacement) in args {
            result = result.replacingOccurrences(of: "{\(placeholder)}", with: replacement)
        }
        return result
    }

    // MARK: Çoğul kategorileri

    enum PluralCategory: String {
        case one, few, other
    }

    /// CLDR'ın `one/few/other` alt kümesi — §06 §2 bu üçünü destekliyor.
    /// `many` ayrı bir kategori değil: Slav dillerinde `other`a katlanıyor,
    /// çünkü 5+ ve 11–14 biçimleri o dillerde zaten aynı.
    nonisolated static func pluralCategory(_ count: Int, locale: String) -> PluralCategory {
        let n = abs(count)
        let mod10 = n % 10
        let mod100 = n % 100

        switch locale {
        // Rusça, Ukraynaca, Belarusça, Hırvatça: 1/21/31… tekil; 2–4/22–24… few.
        case "ru", "uk", "be", "hr":
            if mod10 == 1, mod100 != 11 { return .one }
            if (2...4).contains(mod10), !(12...14).contains(mod100) { return .few }
            return .other

        // Lehçe: yalnızca tam 1 tekil, 2–4 few, gerisi (çoğul genitif) other.
        case "pl":
            if n == 1 { return .one }
            if (2...4).contains(mod10), !(12...14).contains(mod100) { return .few }
            return .other

        case "cs":
            if n == 1 { return .one }
            if (2...4).contains(n) { return .few }
            return .other

        // Arapça'nın altı kategorisi üçe indiriliyor: 3–10 few, gerisi other.
        case "ar":
            if n == 1 { return .one }
            if (3...10).contains(mod100) { return .few }
            return .other

        // Romence: 0 ve 1–19 arası kalanlar few ("de" edatlı biçim).
        case "ro":
            if n == 1 { return .one }
            if n == 0 || (1...19).contains(mod100) { return .few }
            return .other

        // Fransızca'da 0 da tekil sayılıyor.
        case "fr":
            return n <= 1 ? .one : .other

        // Endonezce, Malayca, Filipince, Türkçe: sayıya göre biçim değişmiyor.
        case "id", "ms", "fil", "tr":
            return .other

        default:
            return n == 1 ? .one : .other
        }
    }

    // MARK: Dil değişimi

    /// Dilin kendi JSON'undaki `meta.languageName`; dosya yoksa gömülü tablo.
    static func languageDisplayName(_ code: String) -> String {
        loadJSON(named: code)?["meta.languageName"] ?? fallbackNames[code] ?? code
    }

    /// §06 §2: "kod içinde de hardcoded fallback tablosu bulunur" — JSON
    /// bundle'a girmezse dil listesi boş satırlarla açılmasın.
    private static let fallbackNames: [String: String] = [
        "en": "English", "tr": "Türkçe", "ar": "العربية", "be": "Беларуская",
        "ca": "Català", "cs": "Čeština", "da": "Dansk", "de": "Deutsch",
        "el": "Ελληνικά", "es": "Español", "fi": "Suomi", "fil": "Filipino",
        "fr": "Français", "hr": "Hrvatski", "id": "Bahasa Indonesia",
        "it": "Italiano", "ms": "Bahasa Melayu", "nb": "Norsk bokmål",
        "nl": "Nederlands", "pl": "Polski", "pt": "Português", "ro": "Română",
        "ru": "Русский", "sv": "Svenska", "uk": "Українська",
    ]

    func setLanguage(_ code: String) {
        guard Self.supportedLocales.contains(code), code != localeCode else { return }
        Analytics.languageChange(from: localeCode, to: code)
        localeCode = code
        AppSettingsStore.shared.languageOverride = code
        load(locale: code)
        // §06 §3 ikinci tuzak: planlanmış bildirimin metni planlama anında
        // sabitleniyor. Yeniden planlanmazsa Türkçe uygulamada İngilizce
        // bildirim düşüyor.
        NotificationService.scheduleChanged()
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

        if let aliased = localeAliases[primary] {
            return supportedLocales.contains(aliased) ? aliased : nil
        }
        return supportedLocales.contains(primary) ? primary : nil
    }

    private static func loadJSON(named name: String) -> [String: String]? {
        if let cached = cache[name] { return cached }

        let url =
            Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Resources/Localization")
            ?? Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Localization")
            ?? Bundle.main.url(forResource: name, withExtension: "json")
        guard let url,
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return nil }

        cache[name] = dict
        return dict
    }

    /// İngilizce taban her `t(_:count:)` çağrısında okunuyor; diskten her
    /// seferinde çözmek dil sheet'ini de 25 dosya × açılış maliyetine sokuyordu.
    private static var cache: [String: [String: String]] = [:]
}

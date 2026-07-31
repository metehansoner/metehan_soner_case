import Foundation
import Observation

/// Ayar kalıcılığı — 07-teknik-mimari.md §3'teki `didSet` deseni.
///
/// Şu an yalnızca komponent kütüphanesinin ihtiyaç duyduğu anahtarlar var
/// (dil tercihi ve film efektleri). Ayarlar ekranının 15 satırı P12'de bu
/// sınıfa ekleniyor.
@MainActor
@Observable
final class AppSettingsStore {
    static let shared = AppSettingsStore()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let languageOverride = "settings.languageOverride"
        static let filmEffects = "settings.filmEffects"
        static let scanlines = "settings.scanlines"
    }

    /// Kullanıcının uygulama içinden seçtiği dil; `nil` ise sistem dili kullanılır.
    var languageOverride: String? {
        didSet { defaults.set(languageOverride, forKey: Key.languageOverride) }
    }

    /// § `01` §3: grain, kavis işareti, toz gibi doku katmanları.
    var filmEffectsEnabled: Bool {
        didSet { defaults.set(filmEffectsEnabled, forKey: Key.filmEffects) }
    }

    /// § `01` §3: scanline varsayılan olarak kapalı, ayarlardan açılır.
    var scanlinesEnabled: Bool {
        didSet { defaults.set(scanlinesEnabled, forKey: Key.scanlines) }
    }

    private init() {
        languageOverride = defaults.string(forKey: Key.languageOverride)
        filmEffectsEnabled = defaults.object(forKey: Key.filmEffects) as? Bool ?? true
        scanlinesEnabled = defaults.object(forKey: Key.scanlines) as? Bool ?? false
    }
}

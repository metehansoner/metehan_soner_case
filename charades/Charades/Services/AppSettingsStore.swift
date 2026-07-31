import Foundation
import Observation

/// Ayar kalıcılığı — 07-teknik-mimari.md §3'teki `didSet` deseni.
///
/// Ayarlar ekranının 15 satırı P12'de geliyor; buradakiler o ekrandan önce
/// başka paketlerin ihtiyaç duyduğu anahtarlar.
@MainActor
@Observable
final class AppSettingsStore {
    static let shared = AppSettingsStore()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let languageOverride = "settings.languageOverride"
        static let filmEffects = "settings.filmEffects"
        static let scanlines = "settings.scanlines"
        static let favoriteDecks = "settings.favoriteDecks"
        static let gridColumns = "settings.gridColumns"
        static let haptics = "settings.haptics"
        static let sound = "settings.sound"
        static let touchAnswers = "settings.touchAnswers"
        static let roundDuration = "settings.roundDuration"
        static let difficulty = "settings.difficulty"
        static let roundsPlayed = "stats.roundsPlayed"
        static let howToSeen = "settings.howToSeen"
        static let rapidHighScore = "stats.rapidHighScore"
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

    /// § `09` §9: `FAVORİ` butonunun karşılığı olan liste. Filtre chip'i
    /// yalnızca en az bir favori varken görünüyor.
    var favoriteDeckIDs: Set<String> {
        didSet { defaults.set(Array(favoriteDeckIDs), forKey: Key.favoriteDecks) }
    }

    /// § `02` §4: `BENİM DESTELERİM` başlığının sağındaki ızgara anahtarı.
    var gridColumns: Int {
        didSet { defaults.set(gridColumns, forKey: Key.gridColumns) }
    }

    /// § `01` §4.1: haptik dilinin tek anahtarı.
    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Key.haptics) }
    }

    /// § `04` §5: retro ses paketi tek anahtarla kapatılabiliyor.
    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Key.sound) }
    }

    /// § `04` §2: dokunmatik yedek yalnızca sensör sorunu için değil, ayarlardan
    /// **kalıcı** seçilebilen bir tercih — § `01` §7'deki erişilebilirlik yolu.
    var prefersTouchAnswers: Bool {
        didSet { defaults.set(prefersTouchAnswers, forKey: Key.touchAnswers) }
    }

    /// § `04` §3: 30–180 sn, 15 sn adımlarla, varsayılan 60.
    var roundDuration: Int {
        didSet { defaults.set(roundDuration, forKey: Key.roundDuration) }
    }

    /// § `06` §4: `HEPSİ` / `KOLAY` / `ZOR`.
    var difficulty: CardDifficultyFilter {
        didSet { defaults.set(difficulty.rawValue, forKey: Key.difficulty) }
    }

    /// § `02` ekran 15: tilt hatırlatıcısı ilk 3 turda görünüyor; § `08` §0 da
    /// öğretici bezemeleri 3. turdan sonra kısaltıyor. İkisi de bu sayacı okuyor.
    private(set) var roundsPlayed: Int {
        didSet { defaults.set(roundsPlayed, forKey: Key.roundsPlayed) }
    }

    /// § `02` ekran 9: Nasıl Oynanır slider'ı **mod başına bir kez** otomatik
    /// açılıyor. Sonrasında Deste Detayı ve Duraklat ekranındaki `?` her zaman
    /// açabiliyor. Anahtar mod id'si, ama Mix Klasik'inkini paylaşıyor
    /// (`GameMode.howToSeenKey`).
    private(set) var howToSeenModes: Set<String> {
        didSet { defaults.set(Array(howToSeenModes), forKey: Key.howToSeen) }
    }

    /// § `09` §9: Hız Turu'nun "rekor kırma" gerekçesi kalıcı skor olmadan
    /// çalışmıyordu — tur sonundaki `YENİ REKOR` şeridi bu değeri okuyor.
    private(set) var rapidHighScore: Int {
        didSet { defaults.set(rapidHighScore, forKey: Key.rapidHighScore) }
    }

    private init() {
        languageOverride = defaults.string(forKey: Key.languageOverride)
        filmEffectsEnabled = defaults.object(forKey: Key.filmEffects) as? Bool ?? true
        scanlinesEnabled = defaults.object(forKey: Key.scanlines) as? Bool ?? false
        favoriteDeckIDs = Set(defaults.stringArray(forKey: Key.favoriteDecks) ?? [])
        gridColumns = defaults.object(forKey: Key.gridColumns) as? Int ?? 2
        hapticsEnabled = defaults.object(forKey: Key.haptics) as? Bool ?? true
        soundEnabled = defaults.object(forKey: Key.sound) as? Bool ?? true
        prefersTouchAnswers = defaults.object(forKey: Key.touchAnswers) as? Bool ?? false
        roundDuration = defaults.object(forKey: Key.roundDuration) as? Int ?? 60
        difficulty =
            defaults.string(forKey: Key.difficulty)
                .flatMap(CardDifficultyFilter.init(rawValue:)) ?? .all
        roundsPlayed = defaults.integer(forKey: Key.roundsPlayed)
        howToSeenModes = Set(defaults.stringArray(forKey: Key.howToSeen) ?? [])
        rapidHighScore = defaults.integer(forKey: Key.rapidHighScore)
    }

    func recordRoundPlayed() { roundsPlayed += 1 }

    func hasSeenHowToPlay(_ mode: GameMode) -> Bool {
        howToSeenModes.contains(mode.howToSeenKey)
    }

    func markHowToPlaySeen(_ mode: GameMode) {
        howToSeenModes.insert(mode.howToSeenKey)
    }

    /// Yalnızca yükseldiğinde yazıyor; tur sonundaki düzeltmeler skoru
    /// düşürebildiği için (§02 ekran 17) her tur sonunda körlemesine yazmak
    /// rekoru geri alırdı.
    func recordRapidScore(_ score: Int) {
        guard score > rapidHighScore else { return }
        rapidHighScore = score
    }

    func isFavorite(_ deckID: String) -> Bool { favoriteDeckIDs.contains(deckID) }

    func toggleFavorite(_ deckID: String) {
        if favoriteDeckIDs.contains(deckID) {
            favoriteDeckIDs.remove(deckID)
        } else {
            favoriteDeckIDs.insert(deckID)
        }
    }
}

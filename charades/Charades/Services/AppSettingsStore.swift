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
        static let basketDraft = "draft.basketWords"
        static let paywallSeen = "paywall.seen"
        static let softPaywallSeen = "paywall.softSeen"
        static let lapseNoticeShown = "paywall.lapseNoticeShown"
        static let onboardingDone = "onboarding.done"
        static let onboardingStep = "onboarding.step"
        static let notificationPrompted = "prompt.notificationAsked"
        static let rateUsPrompted = "prompt.rateUsAsked"
        static let notificationsEnabled = "settings.notificationsEnabled"
        static let dailyFreeDeckNotice = "settings.dailyFreeDeckNotice"
        static let userID = "identity.userID"
        static let replayEnabled = "settings.replayEnabled"
        static let replayPrivacyShown = "prompt.replayPrivacyShown"
        static let replayRetention = "settings.replayRetention"
        static let replayWipeOnLaunch = "settings.replayWipeOnLaunch"
        static let archiveNoticeDismissed = "prompt.archiveNoticeDismissed"
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
        didSet {
            defaults.set(soundEnabled, forKey: Key.sound)
            // Kapalıyken döngü ve yarıda kalmış parçalar susturuluyor; aksi
            // hâlde anahtar kapanınca projektör hum'u çalmaya devam ederdi.
            if !soundEnabled { SoundService.stopAll() }
        }
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

    /// §09 §9: Kelime Sepeti `LiveGame`in dışında yaşıyor ama uygulama
    /// sonlandırılırsa kaydedilmemiş sepet giderdi. 5 kelimeye ulaşan sepet
    /// taslak olarak buraya yazılıyor; kaydedilince ya da boşaltılınca siliniyor.
    private(set) var basketDraft: [String] {
        didSet { defaults.set(basketDraft, forKey: Key.basketDraft) }
    }

    /// §03 §1: onboarding sonundaki paywall (varyant A) bir kez gösteriliyor.
    var paywallSeen: Bool {
        didSet { defaults.set(paywallSeen, forKey: Key.paywallSeen) }
    }

    /// §03 §2 varyant C: tur sonu soft paywall'ının **ayrı** anahtarı.
    /// `paywallSeen` her kullanıcıda `true` olduğu için onunla paylaşılamıyor —
    /// paylaşılsaydı soft paywall hiç tetiklenmezdi.
    private(set) var softPaywallSeen: Bool {
        didSet { defaults.set(softPaywallSeen, forKey: Key.softPaywallSeen) }
    }

    /// §09 §7: deneme bittiğinde ana ekranda **bir kez** gösterilen yumuşak
    /// bilgi kartı. Premium'a dönülürse sıfırlanıyor, ikinci düşüşte tekrar çıkar.
    private(set) var lapseNoticeShown: Bool {
        didSet { defaults.set(lapseNoticeShown, forKey: Key.lapseNoticeShown) }
    }

    /// §03 §1: onboarding ilk açılışta bir kez. `false` ise ana ekranın üstünde
    /// kapatılamaz sheet açılıyor.
    private(set) var onboardingDone: Bool {
        didSet { defaults.set(onboardingDone, forKey: Key.onboardingDone) }
    }

    /// §03 §1: yarıda bırakılan onboarding kaldığı adımdan devam ediyor.
    /// Uygulama üçüncü adımda sonlandırılırsa kullanıcı baştan başlamıyor.
    private(set) var onboardingStep: Int {
        didSet { defaults.set(onboardingStep, forKey: Key.onboardingStep) }
    }

    /// §09 §9: bildirim izni **bir kez** soruluyor. Sistem diyaloğu da bir kez
    /// çıkıyor ama bu bayrak olmadan her açılışta 8 saniyelik sayaç boşuna dönüyor.
    private(set) var notificationPrompted: Bool {
        didSet { defaults.set(notificationPrompted, forKey: Key.notificationPrompted) }
    }

    /// §02 §2: puanla bizi istemi ilk başarılı turdan sonra, bir kez.
    private(set) var rateUsPrompted: Bool {
        didSet { defaults.set(rateUsPrompted, forKey: Key.rateUsPrompted) }
    }

    /// §06 §1 satır 10: izin iOS'un, **içerik bizim**. Sistem izni geri alınamıyor
    /// (öyle bir API yok); kullanıcı satırı kapattığında bekleyen bildirimler
    /// iptal ediliyor ve yenisi planlanmıyor.
    var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: Key.notificationsEnabled)
            NotificationService.scheduleChanged()
        }
    }

    /// §06 §1 satır 11: gönderdiğimiz tek düzenli bildirimin (18:00 günlük bedava
    /// deste) anahtarı.
    var dailyFreeDeckNotice: Bool {
        didSet {
            defaults.set(dailyFreeDeckNotice, forKey: Key.dailyFreeDeckNotice)
            NotificationService.scheduleChanged()
        }
    }

    /// §04 §4.1: varsayılan **kapalı** — gizlilik ve pil. Premium özelliği.
    var replayEnabled: Bool {
        didSet { defaults.set(replayEnabled, forKey: Key.replayEnabled) }
    }

    /// §04 §4.5: "bu kayıtlar masadaki herkesi çekiyor" bilgisi kamera izninden
    /// önce ve bir kez gösteriliyor.
    private(set) var replayPrivacyShown: Bool {
        didSet { defaults.set(replayPrivacyShown, forKey: Key.replayPrivacyShown) }
    }

    /// §04 §4.2: 30 günden eski kayıtlar siliniyor, süre arşiv ekranından
    /// değiştirilebiliyor.
    var replayRetention: ReplayStore.Retention {
        didSet { defaults.set(replayRetention.rawValue, forKey: Key.replayRetention) }
    }

    /// §09 §9: eski `Çıkışta kayıtları sil` anahtarı **`Sonraki açılışta sil`**
    /// olarak yeniden adlandırıldı. iOS uygulama sonlandırılırken kod
    /// çalışacağını garanti etmiyor; tutulamayacak bir gizlilik sözü vermek
    /// App Review riski.
    var replayWipeOnLaunch: Bool {
        didSet { defaults.set(replayWipeOnLaunch, forKey: Key.replayWipeOnLaunch) }
    }

    /// §04 §4.3: arşivin tepesindeki "kayıtlar yalnızca bu cihazda" şeridi
    /// kapatılabiliyor ve bir daha gelmiyor.
    private(set) var archiveNoticeDismissed: Bool {
        didSet { defaults.set(archiveNoticeDismissed, forKey: Key.archiveNoticeDismissed) }
    }

    /// §06 §1 kimlik kartı: destek yazışmasında kullanıcıyı eşleştiren kimlik.
    /// RevenueCat `appUserID` olarak da bu değer veriliyor (§ `07` §7 Firebase
    /// `setUserID` de aynısını alacak) — üç yerde farklı kimlik olursa destek
    /// talebini abonelik kaydıyla eşleştirmek imkânsız oluyor.
    let userID: String

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
        basketDraft = defaults.stringArray(forKey: Key.basketDraft) ?? []
        paywallSeen = defaults.bool(forKey: Key.paywallSeen)
        softPaywallSeen = defaults.bool(forKey: Key.softPaywallSeen)
        lapseNoticeShown = defaults.bool(forKey: Key.lapseNoticeShown)
        onboardingDone = defaults.bool(forKey: Key.onboardingDone)
        onboardingStep = defaults.integer(forKey: Key.onboardingStep)
        notificationPrompted = defaults.bool(forKey: Key.notificationPrompted)
        rateUsPrompted = defaults.bool(forKey: Key.rateUsPrompted)
        notificationsEnabled = defaults.object(forKey: Key.notificationsEnabled) as? Bool ?? true
        dailyFreeDeckNotice = defaults.object(forKey: Key.dailyFreeDeckNotice) as? Bool ?? true
        replayEnabled = defaults.bool(forKey: Key.replayEnabled)
        replayPrivacyShown = defaults.bool(forKey: Key.replayPrivacyShown)
        replayRetention =
            defaults.string(forKey: Key.replayRetention)
                .flatMap(ReplayStore.Retention.init(rawValue:)) ?? .month
        replayWipeOnLaunch = defaults.bool(forKey: Key.replayWipeOnLaunch)
        archiveNoticeDismissed = defaults.bool(forKey: Key.archiveNoticeDismissed)

        if let stored = defaults.string(forKey: Key.userID) {
            userID = stored
        } else {
            userID = Self.makeUserID()
            defaults.set(userID, forKey: Key.userID)
        }
    }

    /// §06 §1'deki `A7F3-9C21-4E88` biçimi: telefonda okunup destek e-postasına
    /// elle yazılabilecek kadar kısa, çakışmayacak kadar geniş.
    private static func makeUserID() -> String {
        let hex = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12)
        return stride(from: 0, to: 12, by: 4)
            .map { String(hex.dropFirst($0).prefix(4)) }
            .joined(separator: "-")
    }

    // MARK: Onboarding

    func storeOnboardingStep(_ step: Int) {
        guard step != onboardingStep else { return }
        onboardingStep = step
    }

    /// `ATLA` da son adımın CTA'sı da buraya geliyor: ikisi de onboarding'i
    /// bitiriyor, tek fark kullanıcının kaç adım okuduğu.
    func markOnboardingDone() {
        onboardingDone = true
        onboardingStep = 0
    }

    // MARK: Prompt'lar

    func markNotificationPrompted() { notificationPrompted = true }

    func markRateUsPrompted() { rateUsPrompted = true }

    func markReplayPrivacyShown() { replayPrivacyShown = true }

    func dismissArchiveNotice() { archiveNoticeDismissed = true }

    func markSoftPaywallSeen() { softPaywallSeen = true }

    /// §03 §2 varyant C koşulu: premium değil, daha önce görmedi ve en az bir
    /// tur bitirdi. Tur sonu ekranı bunu okuyor.
    func shouldShowSoftPaywall(isPremium: Bool) -> Bool {
        !isPremium && !softPaywallSeen && roundsPlayed >= 1
    }

    /// Premium'a geçildiğinde bilgi kartı sıfırlanıyor; ikinci bir düşüş olursa
    /// kullanıcı yine bir kez bilgilendiriliyor.
    func syncLapseNotice(isPremium: Bool) {
        if isPremium, lapseNoticeShown { lapseNoticeShown = false }
    }

    func markLapseNoticeShown() { lapseNoticeShown = true }

    #if DEBUG
    /// Bir kez gösterilen ekranlar (soft paywall, düşüş bilgi kartı) simülatörde
    /// başka türlü ikinci kez görülemiyor.
    func debugResetOneTimePrompts() {
        softPaywallSeen = false
        lapseNoticeShown = false
        rateUsPrompted = false
    }

    /// Ana ekrandaki 8 saniyelik istem zincirini yeniden tetiklemek için;
    /// onboarding'i bitmiş bırakıyor.
    func debugReplayHomePrompts() {
        onboardingDone = true
        notificationPrompted = false
        debugResetOneTimePrompts()
    }

    /// İlk açılış deneyimini yeniden oynatmak için: onboarding + onun ardından
    /// gelen paywall + bildirim istemi.
    func debugResetFirstRun() {
        onboardingDone = false
        onboardingStep = 0
        paywallSeen = false
        notificationPrompted = false
        debugResetOneTimePrompts()
    }
    #endif

    func storeBasketDraft(_ words: [String]) {
        guard words.count >= CustomDeckLimits.minWordsToPlay else {
            if !basketDraft.isEmpty { basketDraft = [] }
            return
        }
        basketDraft = words
    }

    func clearBasketDraft() {
        guard !basketDraft.isEmpty else { return }
        basketDraft = []
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

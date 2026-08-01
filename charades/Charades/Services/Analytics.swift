import FirebaseAnalytics
import FirebaseCore
import Foundation

/// Funnel ölçümü — 03-onboarding-paywall.md §5.
///
/// Event adları ve parametreleri **tek yerde**: çağrı yerleri serbest string
/// yazmıyor, aşağıdaki fonksiyonları çağırıyor. Sebep § `03` §5'in kendisi —
/// Imposter'da Firebase linklenmişti ama tek bir `logEvent` çağrısı yoktu ve
/// funnel'ı sonradan kurmak kaybedilmiş veri demekti. Serbest string bunun
/// yumuşak hâli: `paywall_view` bir yerde `paywallView` yazıldığında funnel
/// sessizce delik veriyor ve bu ancak veriye bakılınca fark ediliyor.
enum Analytics {

    private nonisolated(unsafe) static var isConfigured = false

    /// Uygulama açılışında bir kez. `GoogleService-Info.plist` bundle'da;
    /// yoksa Firebase kendi hatasını basıyor ve uygulama analytics'siz çalışıyor.
    static func start(userID: String) {
        // `FirebaseApp.app()` ile sorulmuyor: henüz yapılandırılmamışken o
        // çağrının kendisi konsola "configure çağırın" uyarısı basıyor ve
        // gerçek bir sorun varmış gibi görünüyor.
        guard !isConfigured else { return }
        isConfigured = true
        FirebaseApp.configure()

        // §03 §5 kritik kural: `userId` hem RevenueCat `appUserID`'si hem
        // Firebase `setUserID`'si. İkisi farklı olursa "hangi kullanıcı hangi
        // funnel'dan geçip satın aldı" sorusu cevapsız kalıyor.
        FirebaseAnalytics.Analytics.setUserID(userID)

        #if DEBUG
        // Simülatör ve geliştirme oturumları funnel'ı kirletiyor: 40 kez açılıp
        // kapanan bir tur gerçek dönüşüm oranını okunmaz hâle getiriyor.
        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(false)
        #endif
    }

    // MARK: Onboarding — §03 §1

    static func onboardingStepView(step: Int) {
        log("onboarding_step_view", ["step": step])
    }

    static func onboardingSkip(step: Int) {
        log("onboarding_skip", ["step": step])
    }

    static func onboardingComplete() {
        log("onboarding_complete")
    }

    // MARK: Paywall — §03 §2

    static func paywallView(variant: String, context: String) {
        log("paywall_view", ["variant": variant, "context": context])
    }

    static func paywallPlanSelect(plan: String) {
        log("paywall_plan_select", ["plan": plan])
    }

    static func paywallPurchaseStart(plan: String) {
        log("paywall_purchase_start", ["plan": plan])
    }

    static func paywallPurchaseSuccess(plan: String) {
        log("paywall_purchase_success", ["plan": plan])
    }

    static func paywallPurchaseFail(plan: String, errorCode: String) {
        log("paywall_purchase_fail", ["plan": plan, "error_code": errorCode])
    }

    /// `seconds_shown` olmadan "kapatıldı" tek başına bir şey söylemiyor:
    /// yarım saniyede kapatılan paywall ile 20 saniye okunan aynı satır oluyor.
    static func paywallDismiss(variant: String, secondsShown: Double) {
        log("paywall_dismiss", ["variant": variant, "seconds_shown": rounded(secondsShown)])
    }

    // MARK: Desteler — §02 §4

    static func deckOpen(deckID: String) {
        log("deck_open", ["deck_id": deckID])
    }

    static func deckLockedTap(deckID: String) {
        log("deck_locked_tap", ["deck_id": deckID])
    }

    /// Şeridin `onAppear`ı kaydırmayla ve ana ekrana her dönüşte yeniden
    /// tetikleniyor. Oturumda bir kez sayılmazsa görüntülenme sayısı oynanma
    /// sayısının katı çıkıyor ve §03 §2'nin sorduğu oran anlamsızlaşıyor.
    @MainActor
    static func dailyFreeDeckView(deckID: String) {
        guard sessionLogged.insert("daily_free_deck_view.\(deckID)").inserted else { return }
        log("daily_free_deck_view", ["deck_id": deckID])
    }

    @MainActor private static var sessionLogged: Set<String> = []

    static func dailyFreeDeckPlay(deckID: String) {
        log("daily_free_deck_play", ["deck_id": deckID])
    }

    // MARK: Tur — §04

    static func modeSelect(mode: String) {
        log("mode_select", ["mode": mode])
    }

    static func howToView(mode: String, page: Int) {
        log("howto_view", ["mode": mode, "page": page])
    }

    static func roundStart(mode: String, deckIDs: [String], duration: Int) {
        log("round_start", [
            "mode": mode,
            "deck_ids": joined(deckIDs),
            "duration": duration,
        ])
    }

    static func roundComplete(
        mode: String,
        deckIDs: [String],
        duration: Int,
        correct: Int,
        skipped: Int
    ) {
        log("round_complete", [
            "mode": mode,
            "deck_ids": joined(deckIDs),
            "duration": duration,
            "correct": correct,
            "skipped": skipped,
        ])
    }

    // MARK: Custom deste ve dil — §05 §7, §06 §2

    static func customDeckCreate(wordCount: Int) {
        log("custom_deck_create", ["word_count": wordCount])
    }

    /// `word_count` **o eylemde** eklenen kelime sayısı, destenin toplamı değil:
    /// toplu yapıştırmanın tek tek yazmaya oranı ancak böyle okunuyor ve o oran
    /// toplu yapıştırma butonunun var olma sebebi.
    static func customDeckWordAdd(wordCount: Int) {
        log("custom_deck_word_add", ["word_count": wordCount])
    }

    static func languageChange(from: String, to: String) {
        log("language_change", ["from": from, "to": to])
    }

    // MARK: Replay ve arşiv — §04 §4

    enum ReplaySource: String {
        case roundEnd = "round_end"
        case archive
    }

    enum ArchiveEntry: String {
        case header
        case settings
        case matchEnd = "match_end"
    }

    static func replaySave(source: ReplaySource, slowMotionUsed: Bool) {
        log("replay_save", ["source": source.rawValue, "slow_motion_used": slowMotionUsed])
    }

    static func replayShare(source: ReplaySource, slowMotionUsed: Bool) {
        log("replay_share", ["source": source.rawValue, "slow_motion_used": slowMotionUsed])
    }

    static func replayArchiveOpen(entry: ArchiveEntry, reelCount: Int) {
        log("replay_archive_open", ["entry": entry.rawValue, "reel_count": reelCount])
    }

    /// §04 §4.3'ün tek ölçüm anahtarı: kimse kayıtları bir günden sonra
    /// açmıyorsa arşiv ekranı yatırıma değmiyor ve v1.1'de sadeleşiyor.
    static func replayArchivePlay(ageDays: Int) {
        log("replay_archive_play", ["age_days": ageDays])
    }

    static func replayPin() {
        log("replay_pin")
    }

    static func replayDelete() {
        log("replay_delete")
    }

    static func replayQuotaEvict(count: Int) {
        log("replay_quota_evict", ["evicted_count": count])
    }

    // MARK: Altyapı

    /// Firebase parametre değerleri yalnızca sayı ya da ≤ 100 karakter string
    /// kabul ediyor; sınırı aşan değer sessizce **tüm event'i** düşürüyor.
    private static let maxValueLength = 100

    private static func log(_ name: String, _ parameters: [String: Any] = [:]) {
        let clean = parameters.mapValues(sanitize)

        #if DEBUG
        let rendered = clean
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        print("📊 \(name)\(rendered.isEmpty ? "" : " · \(rendered)")")
        #endif

        FirebaseAnalytics.Analytics.logEvent(name, parameters: clean.isEmpty ? nil : clean)
    }

    private static func sanitize(_ value: Any) -> Any {
        guard let text = value as? String else { return value }
        return String(text.prefix(maxValueLength))
    }

    /// Mix turunda 8 desteye kadar çıkabiliyor; sınırı aşan liste kırpılıyor,
    /// event kaybolmuyor.
    private static func joined(_ ids: [String]) -> String {
        String(ids.joined(separator: ",").prefix(maxValueLength))
    }

    private static func rounded(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }
}

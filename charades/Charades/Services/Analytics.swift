import FirebaseAnalytics
import FirebaseCore
import Foundation


enum Analytics {

    private nonisolated(unsafe) static var isConfigured = false


    static func start(userID: String) {


        guard !isConfigured else { return }
        isConfigured = true
        FirebaseApp.configure()


        FirebaseAnalytics.Analytics.setUserID(userID)

        #if DEBUG


        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(false)
        #endif
    }


    static func onboardingStepView(step: Int) {
        log("onboarding_step_view", ["step": step])
    }

    static func onboardingSkip(step: Int) {
        log("onboarding_skip", ["step": step])
    }

    static func onboardingComplete() {
        log("onboarding_complete")
    }


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


    static func paywallDismiss(variant: String, secondsShown: Double) {
        log("paywall_dismiss", ["variant": variant, "seconds_shown": rounded(secondsShown)])
    }


    static func deckOpen(deckID: String) {
        log("deck_open", ["deck_id": deckID])
    }

    static func deckLockedTap(deckID: String) {
        log("deck_locked_tap", ["deck_id": deckID])
    }


    @MainActor
    static func dailyFreeDeckView(deckID: String) {
        guard sessionLogged.insert("daily_free_deck_view.\(deckID)").inserted else { return }
        log("daily_free_deck_view", ["deck_id": deckID])
    }

    @MainActor private static var sessionLogged: Set<String> = []

    static func dailyFreeDeckPlay(deckID: String) {
        log("daily_free_deck_play", ["deck_id": deckID])
    }


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


    static func customDeckCreate(wordCount: Int) {
        log("custom_deck_create", ["word_count": wordCount])
    }


    static func customDeckWordAdd(wordCount: Int) {
        log("custom_deck_word_add", ["word_count": wordCount])
    }

    static func languageChange(from: String, to: String) {
        log("language_change", ["from": from, "to": to])
    }


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


    private static func joined(_ ids: [String]) -> String {
        String(ids.joined(separator: ",").prefix(maxValueLength))
    }

    private static func rounded(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }
}

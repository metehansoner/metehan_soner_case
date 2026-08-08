import Foundation
import Observation


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


    var languageOverride: String? {
        didSet { defaults.set(languageOverride, forKey: Key.languageOverride) }
    }


    var filmEffectsEnabled: Bool {
        didSet { defaults.set(filmEffectsEnabled, forKey: Key.filmEffects) }
    }


    var scanlinesEnabled: Bool {
        didSet { defaults.set(scanlinesEnabled, forKey: Key.scanlines) }
    }


    var favoriteDeckIDs: Set<String> {
        didSet { defaults.set(Array(favoriteDeckIDs), forKey: Key.favoriteDecks) }
    }


    var gridColumns: Int {
        didSet { defaults.set(gridColumns, forKey: Key.gridColumns) }
    }


    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Key.haptics) }
    }


    var soundEnabled: Bool {
        didSet {
            defaults.set(soundEnabled, forKey: Key.sound)


            if !soundEnabled { SoundService.stopAll() }
        }
    }


    var prefersTouchAnswers: Bool {
        didSet { defaults.set(prefersTouchAnswers, forKey: Key.touchAnswers) }
    }


    var roundDuration: Int {
        didSet { defaults.set(roundDuration, forKey: Key.roundDuration) }
    }


    var difficulty: CardDifficultyFilter {
        didSet { defaults.set(difficulty.rawValue, forKey: Key.difficulty) }
    }


    private(set) var roundsPlayed: Int {
        didSet { defaults.set(roundsPlayed, forKey: Key.roundsPlayed) }
    }


    private(set) var howToSeenModes: Set<String> {
        didSet { defaults.set(Array(howToSeenModes), forKey: Key.howToSeen) }
    }


    private(set) var rapidHighScore: Int {
        didSet { defaults.set(rapidHighScore, forKey: Key.rapidHighScore) }
    }


    private(set) var basketDraft: [String] {
        didSet { defaults.set(basketDraft, forKey: Key.basketDraft) }
    }


    var paywallSeen: Bool {
        didSet { defaults.set(paywallSeen, forKey: Key.paywallSeen) }
    }


    private(set) var softPaywallSeen: Bool {
        didSet { defaults.set(softPaywallSeen, forKey: Key.softPaywallSeen) }
    }


    private(set) var lapseNoticeShown: Bool {
        didSet { defaults.set(lapseNoticeShown, forKey: Key.lapseNoticeShown) }
    }


    private(set) var onboardingDone: Bool {
        didSet { defaults.set(onboardingDone, forKey: Key.onboardingDone) }
    }


    private(set) var onboardingStep: Int {
        didSet { defaults.set(onboardingStep, forKey: Key.onboardingStep) }
    }


    private(set) var notificationPrompted: Bool {
        didSet { defaults.set(notificationPrompted, forKey: Key.notificationPrompted) }
    }


    private(set) var rateUsPrompted: Bool {
        didSet { defaults.set(rateUsPrompted, forKey: Key.rateUsPrompted) }
    }


    var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: Key.notificationsEnabled)
            NotificationService.scheduleChanged()
        }
    }


    var dailyFreeDeckNotice: Bool {
        didSet {
            defaults.set(dailyFreeDeckNotice, forKey: Key.dailyFreeDeckNotice)
            NotificationService.scheduleChanged()
        }
    }


    var replayEnabled: Bool {
        didSet { defaults.set(replayEnabled, forKey: Key.replayEnabled) }
    }


    private(set) var replayPrivacyShown: Bool {
        didSet { defaults.set(replayPrivacyShown, forKey: Key.replayPrivacyShown) }
    }


    var replayRetention: ReplayStore.Retention {
        didSet { defaults.set(replayRetention.rawValue, forKey: Key.replayRetention) }
    }


    var replayWipeOnLaunch: Bool {
        didSet { defaults.set(replayWipeOnLaunch, forKey: Key.replayWipeOnLaunch) }
    }


    private(set) var archiveNoticeDismissed: Bool {
        didSet { defaults.set(archiveNoticeDismissed, forKey: Key.archiveNoticeDismissed) }
    }


    let userID: String

    private init() {
        languageOverride = defaults.string(forKey: Key.languageOverride)
        filmEffectsEnabled = defaults.object(forKey: Key.filmEffects) as? Bool ?? true
        scanlinesEnabled = defaults.object(forKey: Key.scanlines) as? Bool ?? false
        favoriteDeckIDs = Set(defaults.stringArray(forKey: Key.favoriteDecks) ?? [])
        gridColumns = defaults.object(forKey: Key.gridColumns) as? Int ?? 3
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


    private static func makeUserID() -> String {
        let hex = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12)
        return stride(from: 0, to: 12, by: 4)
            .map { String(hex.dropFirst($0).prefix(4)) }
            .joined(separator: "-")
    }


    func storeOnboardingStep(_ step: Int) {
        guard step != onboardingStep else { return }
        onboardingStep = step
    }


    func markOnboardingDone() {
        onboardingDone = true
        onboardingStep = 0
    }


    func markNotificationPrompted() { notificationPrompted = true }

    func markRateUsPrompted() { rateUsPrompted = true }

    func markReplayPrivacyShown() { replayPrivacyShown = true }

    func dismissArchiveNotice() { archiveNoticeDismissed = true }

    func markSoftPaywallSeen() { softPaywallSeen = true }


    func shouldShowSoftPaywall(isPremium: Bool) -> Bool {
        !isPremium && !softPaywallSeen && roundsPlayed >= 1
    }


    func syncLapseNotice(isPremium: Bool) {
        if isPremium, lapseNoticeShown { lapseNoticeShown = false }
    }

    func markLapseNoticeShown() { lapseNoticeShown = true }

    #if DEBUG


    func debugResetOneTimePrompts() {
        softPaywallSeen = false
        lapseNoticeShown = false
        rateUsPrompted = false
    }


    func debugReplayHomePrompts() {
        onboardingDone = true
        notificationPrompted = false
        debugResetOneTimePrompts()
    }


    func debugSkipFirstRun() {
        onboardingDone = true
        onboardingStep = 0
        paywallSeen = true
        notificationPrompted = true
        rateUsPrompted = true
        replayPrivacyShown = true
        archiveNoticeDismissed = true
        softPaywallSeen = true
        lapseNoticeShown = true
    }


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

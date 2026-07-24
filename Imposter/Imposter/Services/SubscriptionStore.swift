import Foundation
import StoreKit

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case freeTrial
    case yearly
    case weekly

    var id: String { rawValue }

    /// Replace with real App Store product IDs before release.
    var productID: String {
        switch self {
        case .freeTrial: return "com.metes.imposter.premium.trial"
        case .yearly: return "com.metes.imposter.premium.yearly"
        case .weekly: return "com.metes.imposter.premium.weekly"
        }
    }
}

@Observable
final class SubscriptionStore {
    static let shared = SubscriptionStore()

    private let defaults = UserDefaults.standard
    private enum Key {
        static let isPremium = "isPremium"
        static let paywallSeen = "paywallSeen"
        static let gamesCompleted = "gamesCompleted"
        static let ratePrompted = "ratePrompted"
    }

    /// Stored so `@Observable` notifies views (UserDefaults-only setters do not).
    var isPremium: Bool {
        didSet { defaults.set(isPremium, forKey: Key.isPremium) }
    }

    var paywallSeen: Bool {
        didSet { defaults.set(paywallSeen, forKey: Key.paywallSeen) }
    }

    var gamesCompleted: Int {
        didSet { defaults.set(gamesCompleted, forKey: Key.gamesCompleted) }
    }

    var ratePrompted: Bool {
        didSet { defaults.set(ratePrompted, forKey: Key.ratePrompted) }
    }

    var selectedPlan: SubscriptionPlan = .yearly
    var isPurchasing = false
    var statusMessage: String?

    private init() {
        isPremium = defaults.bool(forKey: Key.isPremium)
        paywallSeen = defaults.bool(forKey: Key.paywallSeen)
        gamesCompleted = defaults.integer(forKey: Key.gamesCompleted)
        ratePrompted = defaults.bool(forKey: Key.ratePrompted)
    }

    func unlockPremium() {
        isPremium = true
        paywallSeen = true
        statusMessage = nil
        Haptics.success()
    }

    /// Dev / UI path until StoreKit products are configured.
    func purchaseSelectedPlan() async {
        isPurchasing = true
        statusMessage = nil
        try? await Task.sleep(nanoseconds: 600_000_000)
        unlockPremium()
        isPurchasing = false
    }

    func restore() async {
        isPurchasing = true
        do {
            try await AppStore.sync()
            statusMessage = nil
        } catch {
            statusMessage = error.localizedDescription
            Haptics.error()
        }
        isPurchasing = false
    }

    func markGameCompleted() {
        gamesCompleted += 1
    }

    var shouldAskForRating: Bool {
        !ratePrompted && gamesCompleted >= 1
    }
}

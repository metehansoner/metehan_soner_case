import Foundation
import Observation

/// RevenueCat entegrasyonu, 3 plan ve satın alma akışı **P10**'da geliyor
/// (§03, §10 P10). Burada yalnızca "premium mi" sorusunun tek bir cevap yeri
/// olsun diye minimal bir kabuk var — kilitli deste kartı, PlayBar'daki
/// `MIX · PREMIUM` etiketi ve günlük bedava deste bunu okuyor.
///
/// `debugPremiumOverride` yalnızca DEBUG derlemede etkili; kilitli ve kilitsiz
/// hâlleri paywall yazılmadan önce gözle doğrulayabilmek için.
@MainActor
@Observable
final class SubscriptionStore {
    static let shared = SubscriptionStore()

    private let defaults = UserDefaults.standard
    private enum Key {
        static let debugPremium = "debug.premiumOverride"
    }

    #if DEBUG
    var debugPremiumOverride: Bool {
        didSet { defaults.set(debugPremiumOverride, forKey: Key.debugPremium) }
    }
    #endif

    var isPremium: Bool {
        #if DEBUG
        return debugPremiumOverride
        #else
        return false
        #endif
    }

    private init() {
        #if DEBUG
        debugPremiumOverride = defaults.bool(forKey: Key.debugPremium)
        #endif
    }
}

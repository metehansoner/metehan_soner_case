import Foundation
import RevenueCat

enum RevenueCatConfig {
    /// Public SDK key from RevenueCat → Project settings → API keys → App Store.
    static let apiKey = "appl_ocAWqANBOvqboAoAoJuPBCuikvq"

    /// Entitlement that unlocks premium, as named in the RevenueCat dashboard.
    static let entitlementID = "premium"

    /// `nil` uses whichever offering is marked Current in the dashboard.
    static let offeringID: String? = nil
}

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case yearly
    case weekly

    var id: String { rawValue }

    var productID: String {
        switch self {
        case .yearly: return "com.metes.imposter.premium.yearly"
        case .weekly: return "com.metes.imposter.premium.weekly"
        }
    }

    var packageType: PackageType {
        switch self {
        case .yearly: return .annual
        case .weekly: return .weekly
        }
    }
}

@MainActor
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

    /// Packages from the active RevenueCat offering, keyed by plan.
    private(set) var packages: [SubscriptionPlan: Package] = [:]
    private(set) var productsLoaded = false

    private var customerInfoTask: Task<Void, Never>?

    private init() {
        isPremium = defaults.bool(forKey: Key.isPremium)
        paywallSeen = defaults.bool(forKey: Key.paywallSeen)
        gamesCompleted = defaults.integer(forKey: Key.gamesCompleted)
        ratePrompted = defaults.bool(forKey: Key.ratePrompted)
    }

    // MARK: - Lifecycle

    func start() {
        configureIfNeeded()
        if customerInfoTask == nil {
            customerInfoTask = listenForCustomerInfo()
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    private func configureIfNeeded() {
        guard !Purchases.isConfigured else { return }
        #if DEBUG
        Purchases.logLevel = .warn
        #endif
        Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
    }

    // MARK: - Offerings

    func loadProducts() async {
        configureIfNeeded()
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let offering = Self.activeOffering(in: offerings) else {
                packages = [:]
                productsLoaded = false
                return
            }
            packages = Self.plans(in: offering)
            productsLoaded = !packages.isEmpty
        } catch {
            statusMessage = error.localizedDescription
            productsLoaded = false
        }
    }

    private static func activeOffering(in offerings: Offerings) -> Offering? {
        if let offeringID = RevenueCatConfig.offeringID,
           let offering = offerings.offering(identifier: offeringID) {
            return offering
        }
        return offerings.current
    }

    /// Matches on RevenueCat's predefined package types first, then on App Store product IDs so
    /// offerings built with custom package identifiers still resolve.
    private static func plans(in offering: Offering) -> [SubscriptionPlan: Package] {
        var map: [SubscriptionPlan: Package] = [:]
        for plan in SubscriptionPlan.allCases {
            let match = offering.availablePackages.first { $0.packageType == plan.packageType }
                ?? offering.availablePackages.first { $0.storeProduct.productIdentifier == plan.productID }
            if let match {
                map[plan] = match
            }
        }
        return map
    }

    func package(for plan: SubscriptionPlan) -> Package? {
        packages[plan]
    }

    /// Localized price string straight from the store, e.g. "₺499,99".
    func displayPrice(for plan: SubscriptionPlan) -> String? {
        packages[plan]?.storeProduct.localizedPriceString
    }

    /// Derived "per week" price, formatted in the product's currency.
    func perWeekPrice(for plan: SubscriptionPlan) -> String? {
        packages[plan]?.storeProduct.localizedPricePerWeek
    }

    // MARK: - Purchase

    func purchaseSelectedPlan() async {
        await purchase(selectedPlan)
    }

    func purchase(_ plan: SubscriptionPlan) async {
        if packages[plan] == nil {
            await loadProducts()
        }
        guard let package = packages[plan] else {
            statusMessage = "Product unavailable. Please try again."
            Haptics.error()
            return
        }

        isPurchasing = true
        statusMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            guard !result.userCancelled else { return }
            apply(result.customerInfo)
            if isPremium { markPremiumUnlocked() }
        } catch {
            guard (error as NSError).asErrorCode != .purchaseCancelledError else { return }
            statusMessage = error.localizedDescription
            Haptics.error()
        }
    }

    func restore() async {
        isPurchasing = true
        statusMessage = nil
        defer { isPurchasing = false }
        do {
            apply(try await Purchases.shared.restorePurchases())
            if !isPremium {
                Haptics.warning()
            }
        } catch {
            statusMessage = error.localizedDescription
            Haptics.error()
        }
    }

    // MARK: - Entitlements

    func refreshEntitlements() async {
        configureIfNeeded()
        guard let customerInfo = try? await Purchases.shared.customerInfo() else {
            // Keep the cached value: a failed lookup must not revoke an active subscription offline.
            return
        }
        apply(customerInfo)
    }

    private func listenForCustomerInfo() -> Task<Void, Never> {
        Task { [weak self] in
            for await customerInfo in Purchases.shared.customerInfoStream {
                self?.apply(customerInfo)
            }
        }
    }

    /// Falls back to "any active entitlement" so a renamed dashboard entitlement cannot lock out
    /// paying customers — the app only sells one premium tier.
    private func apply(_ customerInfo: CustomerInfo) {
        let active = customerInfo.entitlements.active
        if let entitlement = active[RevenueCatConfig.entitlementID] {
            isPremium = entitlement.isActive
        } else {
            isPremium = !active.isEmpty
        }
    }

    // MARK: - Helpers

    /// Debug / manual unlock (used only where the store is unavailable).
    func markPremiumUnlocked() {
        isPremium = true
        paywallSeen = true
        statusMessage = nil
        Haptics.success()
    }

    func markGameCompleted() {
        gamesCompleted += 1
    }

    var shouldAskForRating: Bool {
        !ratePrompted && gamesCompleted >= 1
    }

    var shouldRequireRewardedForNewGame: Bool {
        !isPremium && gamesCompleted >= 1
    }

    var shouldOfferSoftPaywall: Bool {
        !isPremium && !paywallSeen && gamesCompleted >= 1
    }
}

import Foundation
import Observation
import RevenueCat
import UIKit


@MainActor
@Observable
final class SubscriptionStore {
    static let shared = SubscriptionStore()


    enum Plan: String, CaseIterable, Identifiable, Sendable {
        case weekly, monthly, yearly

        var id: String { rawValue }
        var productID: String { "com.metes.charady.premium.\(rawValue)" }

        var packageType: PackageType {
            switch self {
            case .weekly: .weekly
            case .monthly: .monthly
            case .yearly: .annual
            }
        }
    }


    struct PlanOffer: Identifiable, Sendable {
        let plan: Plan

        let package: Package?

        let price: String

        let pricePerWeek: String?

        let trialDays: Int?


        let savingsPercent: Int?

        var id: String { plan.id }
        var hasTrial: Bool { trialDays != nil }
    }

    enum PurchaseOutcome: Equatable {
        case purchased
        case cancelled


        case failed(String)
    }

    private static let entitlementID = "premium"

    private let defaults = UserDefaults.standard
    private enum Key {
        static let cachedPremium = "subscription.isPremium"
        static let everSubscribed = "subscription.everSubscribed"
        static let renewalDate = "subscription.renewalDate"
        static let debugPremium = "debug.premiumOverride"
    }


    private var entitlementActive: Bool {
        didSet {
            defaults.set(entitlementActive, forKey: Key.cachedPremium)
            if entitlementActive { hasEverSubscribed = true }
        }
    }


    private(set) var hasEverSubscribed: Bool {
        didSet { defaults.set(hasEverSubscribed, forKey: Key.everSubscribed) }
    }


    var didLapse: Bool { hasEverSubscribed && !isPremium }


    private(set) var renewalDate: Date? {
        didSet { defaults.set(renewalDate, forKey: Key.renewalDate) }
    }


    var appUserID: String { AppSettingsStore.shared.userID }

    #if DEBUG
    var debugPremiumOverride: Bool {
        didSet { defaults.set(debugPremiumOverride, forKey: Key.debugPremium) }
    }


    func debugSetRenewalDate(inDays days: Int = 30) {
        renewalDate = Calendar.current.date(byAdding: .day, value: days, to: .now)
    }


    func debugSimulateLapse() {
        debugPremiumOverride = false
        entitlementActive = false
        hasEverSubscribed = true
    }


    func debugLoadSampleOffers() {
        let locale = Locale(identifier: "en_US")
        func product(
            _ plan: Plan,
            _ price: Decimal,
            _ display: String,
            _ unit: RevenueCat.SubscriptionPeriod.Unit,
            trial: Bool = false
        ) -> StoreProduct {
            TestStoreProduct(
                localizedTitle: plan.rawValue,
                price: price,
                currencyCode: "USD",
                localizedPriceString: display,
                productIdentifier: plan.productID,
                productType: .autoRenewableSubscription,
                localizedDescription: "",
                subscriptionGroupIdentifier: "premium",
                subscriptionPeriod: RevenueCat.SubscriptionPeriod(value: 1, unit: unit),
                introductoryDiscount: trial
                    ? .init(
                        identifier: "trial",
                        price: 0,
                        localizedPriceString: "$0.00",
                        paymentMode: .freeTrial,
                        subscriptionPeriod: RevenueCat.SubscriptionPeriod(value: 3, unit: .day),
                        numberOfPeriods: 1,
                        type: .introductory
                    )
                    : nil,
                locale: locale
            )
            .toStoreProduct()
        }

        let offering = Offering(
            identifier: "debug",
            serverDescription: "Örnek teklifler",
            availablePackages: [
                Package(
                    identifier: "weekly",
                    packageType: .weekly,
                    storeProduct: product(.weekly, 4.99, "$4.99", .week, trial: true),
                    offeringIdentifier: "debug",
                    webCheckoutUrl: nil
                ),
                Package(
                    identifier: "monthly",
                    packageType: .monthly,
                    storeProduct: product(.monthly, 9.99, "$9.99", .month),
                    offeringIdentifier: "debug",
                    webCheckoutUrl: nil
                ),
                Package(
                    identifier: "yearly",
                    packageType: .annual,
                    storeProduct: product(.yearly, 39.99, "$39.99", .year),
                    offeringIdentifier: "debug",
                    webCheckoutUrl: nil
                )
            ],
            webCheckoutUrl: nil
        )

        offers = Self.resolveOffers(in: offering)
        didFailToLoadOffers = offers.isEmpty
    }
    #endif

    var isPremium: Bool {
        #if DEBUG
        if debugPremiumOverride { return true }
        #endif
        return entitlementActive
    }

    private(set) var offers: [PlanOffer] = []
    private(set) var isLoadingOffers = false

    private(set) var didFailToLoadOffers = false
    private(set) var isPurchasing = false
    private(set) var isRestoring = false

    private var observationTask: Task<Void, Never>?

    private init() {
        entitlementActive = defaults.bool(forKey: Key.cachedPremium)
        hasEverSubscribed = defaults.bool(forKey: Key.everSubscribed)
        renewalDate = defaults.object(forKey: Key.renewalDate) as? Date
        #if DEBUG
        debugPremiumOverride = defaults.bool(forKey: Key.debugPremium)
        #endif
    }


    func configure() {
        if !Purchases.isConfigured, let apiKey = Self.apiKey {
            #if DEBUG
            Purchases.logLevel = .warn
            #else
            Purchases.logLevel = .error
            #endif


            Purchases.configure(withAPIKey: apiKey, appUserID: appUserID)
            observeCustomerInfo()
        }

        Task { await refresh() }
    }


    func openManageSubscriptions() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }


    private static let revenueCatAPIKey = "appl_wHsHujwsIMLOKzSDxYNvRXDYBTr"


    var isRevenueCatConfigured: Bool { Purchases.isConfigured }

    private static var apiKey: String? {
        let trimmed = revenueCatAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.hasPrefix("appl_") else { return nil }
        return trimmed
    }

    private func observeCustomerInfo() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                guard !Task.isCancelled else { return }
                self?.apply(info)
            }
        }
    }


    private func apply(_ info: CustomerInfo) {
        let entitlement = info.entitlements[Self.entitlementID] ?? info.entitlements.active.values.first
        let active = entitlement?.isActive == true || !info.entitlements.active.isEmpty
        entitlementActive = active
        renewalDate = active ? (entitlement?.expirationDate ?? info.latestExpirationDate) : nil


        NotificationService.scheduleChanged()
    }


    func refresh() async {
        isLoadingOffers = true
        defer { isLoadingOffers = false }

        guard Purchases.isConfigured else {
            #if DEBUG

            debugLoadSampleOffers()
            if !offers.isEmpty { return }
            #endif
            didFailToLoadOffers = true
            return
        }

        if let info = try? await Purchases.shared.customerInfo() {
            apply(info)
        }

        do {
            let offerings = try await Purchases.shared.offerings()
            if let current = offerings.current {
                offers = Self.resolveOffers(in: current)
                didFailToLoadOffers = offers.isEmpty
                if !offers.isEmpty { return }
            }
            for offering in offerings.all.values {
                let resolved = Self.resolveOffers(in: offering)
                guard !resolved.isEmpty else { continue }
                offers = resolved
                didFailToLoadOffers = false
                return
            }
        } catch {
            #if DEBUG
            print("[abonelik] RevenueCat offerings hatası: \(error.localizedDescription)")
            #endif
        }

        if offers.isEmpty {
            didFailToLoadOffers = true
        }
    }


    private static func resolveOffers(in offering: Offering) -> [PlanOffer] {
        let packages = offering.availablePackages
        let resolved = Plan.allCases.compactMap { plan -> (Plan, Package)? in
            if let match = packages.first(where: { $0.packageType == plan.packageType }) {
                return (plan, match)
            }
            if let match = packages.first(where: { $0.storeProduct.productIdentifier == plan.productID }) {
                return (plan, match)
            }
            let aliases: [String] = {
                switch plan {
                case .weekly: ["weekly", "$rc_weekly"]
                case .monthly: ["monthly", "$rc_monthly"]
                case .yearly: ["yearly", "annual", "$rc_annual"]
                }
            }()
            if let match = packages.first(where: { pkg in
                let id = pkg.identifier.lowercased()
                return aliases.contains { id == $0 || id.hasSuffix($0) }
            }) {
                return (plan, match)
            }
            return nil
        }

        let weeklyAnnualCost = resolved
            .first { $0.0 == .weekly }
            .flatMap { $0.1.storeProduct.pricePerYear as Decimal? }

        return resolved.map { plan, package in
            let product = package.storeProduct
            return PlanOffer(
                plan: plan,
                package: package,
                price: product.localizedPriceString,
                pricePerWeek: plan == .weekly ? nil : product.localizedPricePerWeek,
                trialDays: trialDays(of: product),
                savingsPercent: plan == .yearly
                    ? savingsPercent(of: product, comparedTo: weeklyAnnualCost)
                    : nil
            )
        }
    }


    private static func trialDays(of product: StoreProduct) -> Int? {
        guard let intro = product.introductoryDiscount, intro.price == 0 else { return nil }
        let period = intro.subscriptionPeriod
        let days = switch period.unit {
        case .day: period.value
        case .week: period.value * 7
        case .month: period.value * 30
        case .year: period.value * 365
        @unknown default: period.value
        }
        return days > 0 ? days : nil
    }


    private static func savingsPercent(
        of product: StoreProduct,
        comparedTo weeklyAnnualCost: Decimal?
    ) -> Int? {
        guard
            let baseline = weeklyAnnualCost, baseline > 0,
            let annual = product.pricePerYear as Decimal?, annual > 0,
            annual < baseline
        else { return nil }

        let ratio = (baseline - annual) / baseline
        let percent = Int((ratio * 100 as NSDecimalNumber).doubleValue.rounded())
        return (1...99).contains(percent) ? percent : nil
    }


    func purchase(_ offer: PlanOffer) async -> PurchaseOutcome {
        guard !isPurchasing else { return .cancelled }
        guard Purchases.isConfigured, let package = offer.package else {
            return .failed("not_configured")
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return .cancelled }
            apply(result.customerInfo)
            return .purchased
        } catch {
            if (error as? ErrorCode) == .purchaseCancelledError { return .cancelled }
            return .failed(Self.errorCode(error))
        }
    }

    private static func errorCode(_ error: Error) -> String {
        if let code = error as? ErrorCode { return "rc_\(code.rawValue)" }
        return "ns_\((error as NSError).code)"
    }


    @discardableResult
    func restore() async -> Bool {
        guard !isRestoring else { return false }
        guard Purchases.isConfigured else { return false }

        isRestoring = true
        defer { isRestoring = false }

        guard let info = try? await Purchases.shared.restorePurchases() else { return false }
        apply(info)
        return isPremium
    }
}

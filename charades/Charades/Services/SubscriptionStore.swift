import Foundation
import Observation
import RevenueCat
import StoreKit
import UIKit

/// Abonelik durumunun tek kaynağı — 03-onboarding-paywall.md §4.
///
/// Savunmacı davranışlar §4'ten birebir taşındı: entitlement adı dashboard'da
/// değişse bile aktif bir entitlement varsa premium veriliyor, `customerInfo`
/// çekilemediğinde önceki durum korunuyor ve fiyatlar her zaman store'dan
/// geliyor — koda hiçbir fiyat yazılmıyor.
///
/// DEBUG'da RevenueCat anahtarı yoksa ya da offering çekilemezse planlar
/// `Configuration/Products.storekit` üzerinden StoreKit 2 ile yükleniyor;
/// satın alma da aynı yerel yapılandırmayla çalışıyor (ağ / App Store Connect
/// gerekmez). Release hâlâ yalnızca RevenueCat yolunu kullanıyor.
///
/// `debugPremiumOverride` yalnızca DEBUG derlemede etkili; kilitli ve kilitsiz
/// hâlleri sandbox hesabı olmadan gözle doğrulayabilmek için.
@MainActor
@Observable
final class SubscriptionStore {
    static let shared = SubscriptionStore()

    /// §03 §4: üç ürün, tek entitlement. Sıra paywall'daki kart sırası
    /// (§03 §2 madde 4: haftalık en üstte, deneme orada).
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

    /// Bir plan kartının store'dan gelen bütün metni. Tutarların hiçbiri
    /// hesaplanmıyor, `StoreProduct`'ın yerelleştirilmiş biçimleri kullanılıyor.
    struct PlanOffer: Identifiable, Sendable {
        let plan: Plan
        /// RevenueCat yolu. StoreKit-only DEBUG yolunda `nil`.
        let package: Package?
        /// Kartın büyük rakamı: kendi döneminin tam tutarı (§03 §2 madde 4).
        let price: String
        /// Alt satırdaki haftalık karşılık; haftalık planda gösterilmiyor.
        let pricePerWeek: String?
        /// §03 §4: deneme yalnızca haftalıkta ve daha önce kullanılmadıysa gelir.
        let trialDays: Int?
        /// §09 §11 madde 8: tasarruf yüzdesi koda yazılamaz, bölgeye göre
        /// değişiyor. Haftalık planın yıllık maliyetiyle karşılaştırılıyor.
        let savingsPercent: Int?

        var id: String { plan.id }
        var hasTrial: Bool { trialDays != nil }
    }

    enum PurchaseOutcome: Equatable {
        case purchased
        case cancelled
        /// Taşınan değer ekrana çıkmıyor, §03 §5'teki `error_code` parametresi:
        /// yerelleştirilmiş açıklama funnel'da gruplanamıyor.
        case failed(String)
    }

    private static let entitlementID = "premium"
    private static let productIDs = Set(Plan.allCases.map(\.productID))

    private let defaults = UserDefaults.standard
    private enum Key {
        static let cachedPremium = "subscription.isPremium"
        static let everSubscribed = "subscription.everSubscribed"
        static let renewalDate = "subscription.renewalDate"
        static let debugPremium = "debug.premiumOverride"
    }

    /// Son bilinen entitlement durumu. Ağ yokken buna düşülüyor — offline'da
    /// aboneliği iptal edilmiş gibi davranmak ödeme yapan kullanıcıyı kilitler.
    private var entitlementActive: Bool {
        didSet {
            defaults.set(entitlementActive, forKey: Key.cachedPremium)
            if entitlementActive { hasEverSubscribed = true }
        }
    }

    /// §09 §7: deneme bittikten sonraki yumuşak bilgi kartı yalnızca **düşen**
    /// kullanıcıya gösteriliyor. Hiç abone olmamış kullanıcıya "bilet sona erdi"
    /// demek anlamsız.
    private(set) var hasEverSubscribed: Bool {
        didSet { defaults.set(hasEverSubscribed, forKey: Key.everSubscribed) }
    }

    /// Abonelik düşmüş: bir zamanlar aktifti, şimdi değil.
    var didLapse: Bool { hasEverSubscribed && !isPremium }

    /// §06 §1: altın bilet kartındaki "Yenileme: 12 Ağustos 2026". Ağ yokken de
    /// gösterilebilsin diye entitlement durumuyla birlikte önbelleğe alınıyor.
    private(set) var renewalDate: Date? {
        didSet { defaults.set(renewalDate, forKey: Key.renewalDate) }
    }

    /// §06 §1 kimlik kartı: RevenueCat, uygulamanın kendi kimliğini kullanıyor.
    var appUserID: String { AppSettingsStore.shared.userID }

    #if DEBUG
    var debugPremiumOverride: Bool {
        didSet { defaults.set(debugPremiumOverride, forKey: Key.debugPremium) }
    }

    /// Altın bilet kartındaki yenileme satırı gerçek bir entitlement olmadan
    /// görülemiyor; `-Premium` bunu da kuruyor.
    func debugSetRenewalDate(inDays days: Int = 30) {
        renewalDate = Calendar.current.date(byAdding: .day, value: days, to: .now)
    }

    /// Abonelik düşüşü ekranlarını sandbox hesabı olmadan görebilmek için.
    func debugSimulateLapse() {
        debugPremiumOverride = false
        entitlementActive = false
        hasEverSubscribed = true
    }

    /// RevenueCat anahtarı yokken paywall yerleşimini doğrulayabilmek için sahte
    /// bir offering kuruyor. Tutarlar uydurma; gerçek `resolveOffers` yolundan
    /// geçtiği için deneme ve tasarruf hesabı da birlikte sınanıyor.
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

        storeKitProducts = [:]
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
    /// §09 §7 son satır: temiz kurulum + ağ yok + gerçek abone. Paywall bu
    /// bayrakla "bağlantı yokken abonelik doğrulanamıyor" satırını gösteriyor.
    /// DEBUG StoreKit yolu başarılıysa `false` kalır.
    private(set) var didFailToLoadOffers = false
    private(set) var isPurchasing = false
    private(set) var isRestoring = false

    private var observationTask: Task<Void, Never>?
    private var storeKitUpdatesTask: Task<Void, Never>?
    /// StoreKit Configuration / yerel satın alma için ürün önbelleği.
    private var storeKitProducts: [String: Product] = [:]

    private init() {
        entitlementActive = defaults.bool(forKey: Key.cachedPremium)
        hasEverSubscribed = defaults.bool(forKey: Key.everSubscribed)
        renewalDate = defaults.object(forKey: Key.renewalDate) as? Date
        #if DEBUG
        debugPremiumOverride = defaults.bool(forKey: Key.debugPremium)
        #endif
    }

    // MARK: - Kurulum

    /// API anahtarı kodda; yoksa DEBUG'da StoreKit Configuration / örnek
    /// teklifler devreye giriyor. Release'te anahtar yoksa ücretsiz mod.
    func configure() {
        if !Purchases.isConfigured, let apiKey = Self.apiKey {
            #if DEBUG
            Purchases.logLevel = .warn
            #else
            Purchases.logLevel = .error
            #endif

            // §06 §1: destek yazışmasındaki UserID ile RevenueCat kaydı aynı kimliği
            // taşısın diye anonim id yerine uygulamanınki veriliyor.
            Purchases.configure(withAPIKey: apiKey, appUserID: appUserID)
            observeCustomerInfo()
        }

        #if DEBUG
        observeStoreKitTransactions()
        #endif
        Task { await refresh() }
    }

    /// §06 §1 satır 12: premium kullanıcı sistem abonelik sayfasına, ücretsiz
    /// kullanıcı paywall'a gidiyor. Yönlendirme çağıranın işi; burada yalnızca
    /// App Store sayfası açılıyor.
    func openManageSubscriptions() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }

    /// RevenueCat Apple public SDK key (`appl_…`). Dashboard → API keys.
    private static let revenueCatAPIKey = "appl_wHsHujwsIMLOKzSDxYNvRXDYBTr"

    /// Paywall fiyatları RevenueCat Current offering'den geliyor.
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

    #if DEBUG
    private func observeStoreKitTransactions() {
        storeKitUpdatesTask?.cancel()
        storeKitUpdatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard !Task.isCancelled else { return }
                if let transaction = try? Self.verified(update) {
                    await transaction.finish()
                    await self?.syncStoreKitEntitlements()
                }
            }
        }
    }
    #endif

    /// §03 §4: entitlement adı dashboard'da değişse bile **herhangi bir** aktif
    /// entitlement premium sayılıyor. Ödeme yapan kullanıcıyı asla kilitlemiyoruz.
    private func apply(_ info: CustomerInfo) {
        let entitlement = info.entitlements[Self.entitlementID] ?? info.entitlements.active.values.first
        let active = entitlement?.isActive == true || !info.entitlements.active.isEmpty
        entitlementActive = active
        renewalDate = active ? (entitlement?.expirationDate ?? info.latestExpirationDate) : nil
        // §06 §3: premium olan kullanıcıya "bugün bedava" bildirimi anlamsız,
        // düşen kullanıcıya yeniden anlamlı — iki yönde de yeniden planlanıyor.
        NotificationService.scheduleChanged()
    }

    // MARK: - Teklifler

    /// Paywall her açılışta çağırır. Önce RevenueCat Current offering;
    /// anahtar yoksa DEBUG'da StoreKit Configuration / örnek teklifler.
    func refresh() async {
        isLoadingOffers = true
        defer { isLoadingOffers = false }

        if Purchases.isConfigured {
            if let info = try? await Purchases.shared.customerInfo() {
                apply(info)
            }

            do {
                let offerings = try await Purchases.shared.offerings()
                if let current = offerings.current {
                    storeKitProducts = [:]
                    offers = Self.resolveOffers(in: current)
                    didFailToLoadOffers = offers.isEmpty
                    if !offers.isEmpty { return }
                }
                // Current boşsa diğer offering'lere bak (dashboard henüz Current
                // işaretlenmemiş olabilir).
                for offering in offerings.all.values {
                    let resolved = Self.resolveOffers(in: offering)
                    guard !resolved.isEmpty else { continue }
                    storeKitProducts = [:]
                    offers = resolved
                    didFailToLoadOffers = false
                    return
                }
            } catch {
                #if DEBUG
                print("[abonelik] RevenueCat offerings hatası: \(error.localizedDescription)")
                #endif
            }

            // RC bağlı ama paket gelmedi — mock'a düşme; paywall offline göstersin.
            if offers.isEmpty {
                didFailToLoadOffers = true
            }
            return
        }

        #if DEBUG
        if await refreshFromStoreKit() { return }
        debugLoadSampleOffers()
        if !offers.isEmpty { return }
        #endif

        if offers.isEmpty {
            didFailToLoadOffers = true
        }
    }

    #if DEBUG
    /// Scheme'e bağlı `Products.storekit` dosyasından ürünleri çekiyor.
    /// Xcode dışında (TestFlight) bu dosya yok; ürün listesi boş kalır.
    @discardableResult
    private func refreshFromStoreKit() async -> Bool {
        do {
            let products = try await Product.products(for: Self.productIDs)
            guard !products.isEmpty else { return false }

            storeKitProducts = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
            offers = Self.resolveOffers(from: products)
            didFailToLoadOffers = offers.isEmpty
            await syncStoreKitEntitlements()
            return !offers.isEmpty
        } catch {
            return false
        }
    }

    private func syncStoreKitEntitlements() async {
        var active = false
        var latestExpiry: Date?
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.verified(result) else { continue }
            guard Self.productIDs.contains(transaction.productID) else { continue }
            active = true
            if let expiry = transaction.expirationDate {
                latestExpiry = max(latestExpiry ?? expiry, expiry)
            }
        }
        entitlementActive = active
        renewalDate = active ? latestExpiry : nil
        NotificationService.scheduleChanged()
    }

    private static func verified<T>(_ result: StoreKit.VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }
    #endif

    /// §03 §4: paket çözümleme — PackageType → product ID → identifier adı.
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

    #if DEBUG
    private static func resolveOffers(from products: [Product]) -> [PlanOffer] {
        let byID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        let resolved = Plan.allCases.compactMap { plan -> (Plan, Product)? in
            byID[plan.productID].map { (plan, $0) }
        }

        let weeklyAnnualCost = resolved
            .first { $0.0 == .weekly }
            .map { $0.1.price * 52 }

        return resolved.map { plan, product in
            PlanOffer(
                plan: plan,
                package: nil,
                price: product.displayPrice,
                pricePerWeek: plan == .weekly ? nil : pricePerWeek(of: product),
                trialDays: trialDays(of: product),
                savingsPercent: plan == .yearly
                    ? savingsPercent(price: product.price, comparedTo: weeklyAnnualCost)
                    : nil
            )
        }
    }

    private static func pricePerWeek(of product: Product) -> String? {
        guard let period = product.subscription?.subscriptionPeriod else { return nil }
        let weeks: Decimal = switch period.unit {
        case .day: Decimal(period.value) / 7
        case .week: Decimal(period.value)
        case .month: Decimal(period.value) * Decimal(52) / Decimal(12)
        case .year: Decimal(period.value) * 52
        @unknown default: 1
        }
        guard weeks > 0 else { return nil }
        return (product.price / weeks).formatted(product.priceFormatStyle)
    }

    private static func trialDays(of product: Product) -> Int? {
        guard
            let intro = product.subscription?.introductoryOffer,
            intro.paymentMode == .freeTrial
        else { return nil }
        let period = intro.period
        let days = switch period.unit {
        case .day: period.value
        case .week: period.value * 7
        case .month: period.value * 30
        case .year: period.value * 365
        @unknown default: period.value
        }
        return days > 0 ? days : nil
    }

    private static func savingsPercent(price annual: Decimal, comparedTo weeklyAnnualCost: Decimal?) -> Int? {
        guard let baseline = weeklyAnnualCost, baseline > 0, annual > 0, annual < baseline else {
            return nil
        }
        let ratio = (baseline - annual) / baseline
        let percent = Int((ratio * 100 as NSDecimalNumber).doubleValue.rounded())
        return (1...99).contains(percent) ? percent : nil
    }
    #endif

    /// Daha önce deneme kullanmış kullanıcıda `introductoryDiscount` gelmiyor;
    /// CTA ve alt metin otomatik olarak denemesiz hâle düşüyor (§03 §4).
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

    /// Yıllık planın haftalığa göre kazandırdığı yüzde. Store fiyatlarından
    /// hesaplanıyor; bölge fiyatları farklı olduğu için sabit yüzde yanlış olur.
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

    // MARK: - Satın alma

    func purchase(_ offer: PlanOffer) async -> PurchaseOutcome {
        guard !isPurchasing else { return .cancelled }

        isPurchasing = true
        defer { isPurchasing = false }

        if Purchases.isConfigured, let package = offer.package {
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

        #if DEBUG
        return await purchaseWithStoreKit(offer.plan)
        #else
        return .failed("not_configured")
        #endif
    }

    #if DEBUG
    private func purchaseWithStoreKit(_ plan: Plan) async -> PurchaseOutcome {
        // Ürün henüz yüklenmediyse bir kez daha dene (scheme StoreKit dosyası).
        if storeKitProducts[plan.productID] == nil {
            _ = await refreshFromStoreKit()
        }

        // StoreKit Configuration bağlı değilse (ör. simctl) örnek tekliflerle
        // satın alma akışı yine tamamlanabilsin — gerçek sheet olmadan premium.
        guard let product = storeKitProducts[plan.productID] else {
            entitlementActive = true
            renewalDate = Calendar.current.date(byAdding: .day, value: 7, to: .now)
            NotificationService.scheduleChanged()
            return .purchased
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try Self.verified(verification)
                await transaction.finish()
                await syncStoreKitEntitlements()
                return .purchased
            case .userCancelled:
                return .cancelled
            case .pending:
                return .cancelled
            @unknown default:
                return .failed("unknown")
            }
        } catch {
            return .failed(Self.errorCode(error))
        }
    }
    #endif

    private static func errorCode(_ error: Error) -> String {
        if let code = error as? ErrorCode { return "rc_\(code.rawValue)" }
        return "ns_\((error as NSError).code)"
    }

    /// §09 §7: temiz kurulumda "önceki durum" olmadığı için geri yükleme
    /// paywall'da kalıcı bir buton — gerçek abonenin tek çıkış yolu.
    @discardableResult
    func restore() async -> Bool {
        guard !isRestoring else { return false }

        isRestoring = true
        defer { isRestoring = false }

        if Purchases.isConfigured {
            guard let info = try? await Purchases.shared.restorePurchases() else { return false }
            apply(info)
            return isPremium
        }

        #if DEBUG
        do {
            try await AppStore.sync()
            await syncStoreKitEntitlements()
            return isPremium
        } catch {
            return false
        }
        #else
        return false
        #endif
    }
}

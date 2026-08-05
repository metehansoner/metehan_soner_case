import Observation
import SwiftUI

/// §02 §5'teki rota listesi. Deste Detayı, kurulum sheet'i, Ayarlar ve
/// Dil **sheet** olarak sunuluyor, bu yüzden path'e girmiyor.
///
/// `archive` ve `archivePlayer` bilinçli olarak oyun akışının dışında: arşivden
/// açılan oynatıcı tur sonunda açılanla aynı view'ı kullanıyor ama arşive
/// dönüyor, oyun akışına değil.
enum AppRoute: Hashable {
    case mix
    case customList
    case customEditor(String?)
    case wordBasket
    /// `resumesModeSelect`: Mod Seçimi'nden gelindiyse bitince sheet yeniden
    /// açılır. Ana ekran kısayolundan gelindiyse yalnızca pop.
    case teamSetup(resumesModeSelect: Bool)
    case archive
    case archivePlayer(String)
}

/// Paywall her yerden çıkabilen bir modal (§02 §2). Hangi tetikleyiciyle
/// açıldığı P10'da varyant seçimini belirleyecek (§03 §2), o yüzden bağlam
/// şimdiden taşınıyor — sonradan eklenirse çağrı yerlerinin tamamı değişir.
enum PaywallContext: Hashable, Identifiable {
    case vipButton
    case lockedDeck(String)
    case lockedMode(String)
    case mix
    /// §09 §9: ücretsiz kullanıcı custom desteyi yazabiliyor ama oynayamıyor.
    case customDeck
    /// §03 §2 varyant C: tur sonu yumuşak öneriden gelen tam ekran.
    case roundEnd

    var id: String {
        switch self {
        case .vipButton: "vipButton"
        case .lockedDeck(let id): "lockedDeck.\(id)"
        case .lockedMode(let id): "lockedMode.\(id)"
        case .mix: "mix"
        case .customDeck: "customDeck"
        case .roundEnd: "roundEnd"
        }
    }

    /// Kilitli bir şeye dokunarak istem dışı açılan bağlamlar. `vipButton`
    /// bilinçli bir "bileti göster" isteği, o yüzden frekans sınırına girmiyor.
    var isInvoluntary: Bool {
        switch self {
        case .vipButton, .roundEnd: false
        default: true
        }
    }
}

/// §03 §2: aynı plan kartları, iki farklı çerçeve. Varyant C (tur sonu yumuşak
/// öneri) plan kartlarını hiç göstermediği için ayrı bir view — `SoftPaywallPanel`.
enum PaywallVariant {
    /// Onboarding sonu, tam ekran, `ATLA` görünür.
    case onboarding
    /// Kilitli içeriğe dokunuş; bağlam kapağı gelir, `X` 1,5 sn gecikmeli.
    case modal

    /// §03 §5 `paywall_view.variant`. Üçüncü değer `soft`, o `SoftPaywallPanel`
    /// tarafından yazılıyor: yumuşak öneri plan kartı göstermediği için ayrı
    /// bir view ve bu enum'a girmiyor.
    var analyticsName: String {
        switch self {
        case .onboarding: "onboarding"
        case .modal: "modal"
        }
    }
}

/// Tur kurulumunun sheet zinciri — Mod + tur ayarı tek adım, ardından (ilk kez)
/// Nasıl Oynanır → oyun.
///
/// Adımlar **tek bir sheet'in içinde** yer değiştiriyor, ayrı sheet olarak
/// sunulmuyor: iOS'ta bir sheet'i kapatıp diğerini açmak arada boş ekran ve
/// zamanlama sorunu üretiyor.
enum SetupStep: Hashable {
    /// Mod kartları + süre/zorluk + OYNA.
    case mode
    /// `continuesToGame` false ise `?` butonundan açılmış demektir (Deste
    /// Detayı, Duraklat): kapanınca tur başlamıyor.
    case howToPlay(mode: GameMode, continuesToGame: Bool)
}

/// Tek `NavigationStack`in yolu ve üstüne binen sheet'ler (§02 §5).
/// Sheet durumunun da burada olmasının sebebi, "kilitli desteye dokun →
/// paywall" gibi geçişlerin tek bir yerden okunabilmesi.
@MainActor
@Observable
final class AppRouter {
    var path: [AppRoute] = []

    /// Deste Detayı sheet'i — açık olan destenin id'si.
    var deckDetailID: String?
    var isShowingSettings = false
    /// Kurulum zincirinin o anki adımı; `nil` ise sheet kapalı.
    var setupStep: SetupStep?
    var paywall: PaywallContext?
    /// Varyant A yalnızca onboarding'in sonunda açılıyor (§03 §1); P11 akışı
    /// paywall'ı bu bayrakla sunacak.
    private(set) var paywallVariant: PaywallVariant = .modal

    /// §09 §9: modal paywall oturum başına en fazla 3 kez. Sonrasında kilitli
    /// içeriğe dokunuş yalnızca kısa bir uyarı gösteriyor — aynı ekranı dördüncü
    /// kez açmak ikna etmiyor, sinirlendiriyor.
    static let maxInvoluntaryPaywallsPerSession = 3
    private var involuntaryPaywallCount = 0
    /// Sınır dolduğunda gösterilen kısa uyarının metni; `nil` ise uyarı yok.
    var lockedNotice: String?

    /// Deste Detayı'ndaki `OYNA` ve `?` kurulum sheet'ini açıyor (§02 §3,
    /// `F → J`) ama önce kendi sheet'i kapanmalı: aynı anda iki sheet
    /// sunulamıyor. İstek burada bekliyor, `deckDetailDismissed()` tüketiyor.
    private var pendingSetupStep: SetupStep?

    func push(_ route: AppRoute) { path.append(route) }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() { path.removeAll() }

    func openDeckDetail(_ deckID: String) {
        Analytics.deckOpen(deckID: deckID)
        deckDetailID = deckID
    }

    func openPaywall(_ context: PaywallContext, variant: PaywallVariant = .modal) {
        // Frekans sınırından **önce**: kilitli desteye dokunmak, paywall
        // açılmasa da ilgi göstergesi. Sınıra takılan dokunuşlar sayılmazsa
        // "kaç kişi kilide çarptı" olduğundan az görünüyor.
        if case .lockedDeck(let deckID) = context {
            Analytics.deckLockedTap(deckID: deckID)
        }

        if context.isInvoluntary {
            guard involuntaryPaywallCount < Self.maxInvoluntaryPaywallsPerSession else {
                lockedNotice = LocalizationManager.shared.t("paywall.notice.locked")
                return
            }
            involuntaryPaywallCount += 1
        }

        paywallVariant = variant
        deckDetailID = nil
        setupStep = nil
        paywall = context
    }

    // MARK: Kurulum zinciri

    func beginSetup() { setupStep = .mode }

    func closeSetup() { setupStep = nil }

    /// Deste Detayı → Mod Seçimi.
    func beginSetupAfterDeckDetail() { closeDeckDetail(opening: .mode) }

    func openHowToPlayAfterDeckDetail(for mode: GameMode) {
        closeDeckDetail(opening: .howToPlay(mode: mode, continuesToGame: false))
    }

    func deckDetailDismissed() {
        guard let step = pendingSetupStep else { return }
        pendingSetupStep = nil
        setupStep = step
    }

    /// Duraklat menüsündeki `?` (§04 §3): tur akışının dışında, kapanınca
    /// hiçbir şey başlatmıyor.
    func openHowToPlay(for mode: GameMode) {
        setupStep = .howToPlay(mode: mode, continuesToGame: false)
    }

    private func closeDeckDetail(opening step: SetupStep) {
        pendingSetupStep = step
        deckDetailID = nil
    }
}

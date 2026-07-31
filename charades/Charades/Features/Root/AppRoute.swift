import Observation
import SwiftUI

/// §02 §5'teki rota listesi. Deste Detayı, Mod Seçimi, Tur Ön Ayar, Ayarlar ve
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
    case teamSetup
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

    var id: String {
        switch self {
        case .vipButton: "vipButton"
        case .lockedDeck(let id): "lockedDeck.\(id)"
        case .lockedMode(let id): "lockedMode.\(id)"
        case .mix: "mix"
        }
    }
}

/// Tur kurulumunun sheet zinciri — §02 §3: Mod Seçimi → Tur Ön Ayar →
/// (ilk kez) Nasıl Oynanır → oyun.
///
/// Üç adım **tek bir sheet'in içinde** yer değiştiriyor, üç ayrı sheet olarak
/// sunulmuyor: iOS'ta bir sheet'i kapatıp diğerini açmak arada boş ekran ve
/// zamanlama sorunu üretiyor, kullanıcı da her adımda perdeyi yeniden görüyor.
enum SetupStep: Hashable {
    case mode
    case preset
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

    func openDeckDetail(_ deckID: String) { deckDetailID = deckID }

    func openPaywall(_ context: PaywallContext) {
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

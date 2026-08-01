import SwiftUI

/// Ekran 10 — Mod Seçimi (§ `02` §4, § `04` §1).
///
/// Altı mod da listede: kilitli olanlar gizlenmiyor. § `03` §2'nin gerekçesi —
/// premium modu hiç göstermemek satın alma sebebini de göstermemek demek.
/// Kilitli karta dokunmak paywall açıyor (§ `09` §9).
struct ModeSelectSheet: View {
    var onSelect: (GameMode) -> Void
    var onClose: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(AppRouter.self) private var router
    @Environment(GameSetup.self) private var setup

    var body: some View {
        SheetScaffold(title: l10n.t("mode.select.title"), onClose: onClose) {
            ScrollView {
                VStack(spacing: 9) {
                    ForEach(GameMode.allCases) { mode in
                        ModeCard(
                            mode: mode,
                            isSelected: setup.mode == mode,
                            isLocked: isLocked(mode),
                            action: { tap(mode) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func isLocked(_ mode: GameMode) -> Bool {
        !mode.isFree && !subscriptions.isPremium
    }

    private func tap(_ mode: GameMode) {
        guard !isLocked(mode) else {
            // § `09` §9: `ownWords` kilitliyken Kelime Sepeti **hiç açılmıyor**.
            // Kullanıcıya kelimelerini yazdırıp sonunda kapıyı kapatmak
            // yem-değiştir olurdu; kapı burada, yazmadan önce kapanıyor.
            Haptics.lockedWall()
            router.openPaywall(.lockedMode(mode.id))
            return
        }
        Haptics.modeSelected()
        Analytics.modeSelect(mode: mode.id)
        onSelect(mode)
    }
}

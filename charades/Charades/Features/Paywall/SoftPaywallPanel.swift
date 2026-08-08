import SwiftUI

/// Varyant C — 03-onboarding-paywall.md §2: tur sonu yumuşak önerisi.
///
/// İlk tamamlanan turun hemen ardından bir kez. Ürünün en yüksek dönüşüm
/// potansiyeli olan an burası, ama akışı kesmiyor: tek CTA ve kolay kapatma.
/// Tetikleyici `softPaywallSeen` — `paywallSeen` ile paylaşılsaydı onboarding
/// paywall'ı herkeste `true` yaptığı için hiç görünmezdi.
///
/// Sistem sheet'i değil overlay paneli: tur sonu ekranı yatay (§09 §1) ve
/// yatayda iPhone sheet'i detent'leri yok sayıp neredeyse tam ekran açılıyor —
/// "kolay kapatma" iddiası orada çöküyor.
struct SoftPaywallPanel: View {
    var onSeeTicket: () -> Void
    var onClose: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    @State private var shownAt = Date.now

    /// 92 v1 destesi − 1 kalıcı ücretsiz − 1 günün bedavası.
    private var lockedDeckCount: Int {
        let daily = DeckCatalog.dailyFreeDeckID() == nil ? 0 : 1
        return max(DeckCatalog.v1.count - 1 - daily, 0)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: dismiss)

            panel
        }
        .transition(.opacity)
        // §03 §5: üçüncü varyant. Tam ekran paywall ile aynı event, farklı
        // `variant` — dönüşümü karşılaştırılabilir olsun diye.
        .onAppear {
            shownAt = .now
            Analytics.paywallView(variant: "soft", context: PaywallContext.roundEnd.id)
        }
    }

    private func dismiss() {
        Analytics.paywallDismiss(
            variant: "soft",
            secondsShown: Date.now.timeIntervalSince(shownAt)
        )
        onClose()
    }

    private var panel: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppColors.accentGold.opacity(0.6))
                .frame(width: 38, height: 4)
                .padding(.top, 10)

            HStack(alignment: .center, spacing: 18) {
                posterStrip

                VStack(alignment: .leading, spacing: 7) {
                    Text(l10n.t("paywall.soft.title"))
                        .font(AppFont.accent(22, weight: .bold))
                        .foregroundStyle(AppColors.textCream)

                    Text(l10n.t("paywall.soft.body", count: lockedDeckCount))
                        .font(AppFont.ui(12.5))
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)

            Button {
                Haptics.primaryButton()
                onSeeTicket()
            } label: {
                Text(l10n.t("paywall.soft.cta"))
            }
            .buttonStyle(MarqueeButtonStyle())
            .padding(.horizontal, 24)
            .padding(.top, 18)

            Button {
                Haptics.secondaryButton()
                dismiss()
            } label: {
                Text(l10n.t("paywall.soft.dismiss"))
                    .font(AppFont.ui(12))
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: AppLayout.readableWidth)
        .frame(maxWidth: .infinity, alignment: .bottom)
        .background {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: 0x4A1720), location: 0),
                    .init(color: AppColors.bgVelvetDeep, location: 0.35),
                    .init(color: AppColors.surfaceCard, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay { GrainOverlay() }
        }
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
        .overlay(alignment: .top) {
            Rectangle().fill(AppColors.accentGold.opacity(0.5)).frame(height: 1)
        }
        .transition(.move(edge: .bottom))
    }

    /// Yarım panelde afiş duvarı sığmıyor; tek sıra kapak aynı mesajı
    /// ("burada çok şey var") daha az yer kaplayarak veriyor.
    private var posterStrip: some View {
        HStack(spacing: 7) {
            ForEach(Array(DeckCatalog.v1.filter { !$0.isFree }.prefix(3)), id: \.id) { deck in
                DeckMiniPoster(deck: deck).frame(width: 52, height: 70)
            }
        }
        .accessibilityHidden(true)
    }
}

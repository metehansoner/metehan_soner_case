import SwiftUI

/// Öne çıkan satır — 02-ekran-akisi.md §4 (ekran 4, madde 5).
///
/// `KENDİ KELİMELERİN` burada olmak zorunda, tercih değil: o mod deste
/// seçmiyor, dolayısıyla "deste seç → mod seç" hattından hiç erişilemez.
/// `MIX` de aynı sebeple burada.
struct FeaturedRow: View {
    /// §02 §24: ücretsiz kullanıcı Kelime Sepeti'ni **hiç görmüyor** — 20 kelime
    /// yazdırıp sonunda paywall göstermek yem-değiştir olurdu. Mix'te durum
    /// farklı: kurulum serbest, duvar oynarken çıkıyor.
    var isWordBasketLocked: Bool
    var onMix: () -> Void
    var onWordBasket: () -> Void
    var onCustomDecks: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FeaturedCard(
                    title: l10n.t("featured.mix"),
                    style: .mix,
                    action: onMix
                )
                FeaturedCard(
                    title: l10n.t("featured.wordBasket"),
                    style: .wordBasket,
                    isLocked: isWordBasketLocked,
                    action: onWordBasket
                )
                FeaturedCard(
                    title: l10n.t("featured.customDeck"),
                    style: .customDeck,
                    action: onCustomDecks
                )
            }
            .padding(.horizontal, 18)
        }
    }
}

private struct FeaturedCard: View {
    enum Style {
        /// §4: Mix dönen film makarası, Kendi Kelimelerin boş bilet + kalem,
        /// Custom boş afiş + artı. Üçü de ızgaradaki desteden farklı görsel dil.
        case mix, wordBasket, customDeck
    }

    let title: String
    let style: Style
    var isLocked = false
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                icon
                    .overlay(alignment: .topTrailing) {
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(AppColors.accentBrass)
                                .offset(x: 13, y: -3)
                        }
                    }

                Text(title)
                    .font(AppFont.display(11, weight: .semibold))
                    .tracking(1.7)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textCream)
                    .lineLimit(1)
            }
            .opacity(isLocked ? 0.68 : 1)
            .frame(width: 118, height: 74)
            .background {
                RoundedRectangle(cornerRadius: 11)
                    .fill(background)
                    .overlay {
                        if style == .customDeck {
                            StripedFill()
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 11)
                            .strokeBorder(AppColors.accentGold, lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var icon: some View {
        switch style {
        case .mix:
            SpinningReel(isSpinning: !reduceMotion)
        case .wordBasket:
            Image(systemName: "ticket")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(AppColors.accentGold)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.accentAmber)
                        .offset(x: 4, y: 3)
                }
        case .customDeck:
            Image(systemName: "rectangle.portrait.badge.plus")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(AppColors.accentGold)
        }
    }

    private var background: AnyShapeStyle {
        switch style {
        case .mix:
            AnyShapeStyle(
                EllipticalGradient(
                    colors: [Color(hex: 0x3D5F5D), Color(hex: 0x12201F)],
                    center: UnitPoint(x: 0.5, y: 0.38),
                    startRadiusFraction: 0,
                    endRadiusFraction: 0.72
                )
            )
        case .wordBasket:
            AnyShapeStyle(
                LinearGradient(
                    colors: [AppColors.bgVelvetMid, AppColors.surfaceCard],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .customDeck:
            // Mockup'taki 46° çizgili boş afiş dokusu — Canvas ile bir kez çiziliyor.
            AnyShapeStyle(AppColors.surfaceCard)
        }
    }
}

/// §4 mockup'ındaki custom kart: 46° çizgili boş afiş.
private struct StripedFill: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 12
            var x: CGFloat = -size.height
            while x < size.width + size.height {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height + 6, y: size.height))
                path.addLine(to: CGPoint(x: x + 6, y: 0))
                path.closeSubpath()
                context.fill(path, with: .color(Color(hex: 0x241B16)))
                x += step
            }
        }
        .allowsHitTesting(false)
    }
}

/// §4: Mix kartının dönen film makarası. 12 fps — §01 §3'ün animasyon bütçesi.
private struct SpinningReel: View {
    var isSpinning: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12, paused: !isSpinning)) { context in
            let angle = isSpinning
                ? context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 6) / 6 * 360
                : 0
            Image(systemName: "film.circle")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(AppColors.accentGold)
                .rotationEffect(.degrees(angle))
        }
    }
}

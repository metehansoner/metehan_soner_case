import SwiftUI


struct FeaturedRow: View {


    var isWordBasketLocked: Bool

    var hasCustomDecks: Bool
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
                    title: l10n.t(hasCustomDecks ? "customDeck.list.title" : "featured.customDeck"),
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
                    .appTracking(1.7)
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
            WordBasketIcon()
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

            AnyShapeStyle(AppColors.surfaceCard)
        }
    }
}


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


private struct WordBasketIcon: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(AppColors.accentBrass, lineWidth: 1.2)
                    .frame(width: 16, height: 20)
                    .rotationEffect(.degrees(-11))
                    .offset(x: -5, y: 0)

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(AppColors.surfaceCard.opacity(0.55))
                    .overlay {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .strokeBorder(AppColors.accentGold, lineWidth: 1.35)
                    }
                    .overlay(alignment: .top) {
                        VStack(spacing: 2.5) {
                            Capsule()
                                .fill(AppColors.accentGold.opacity(0.9))
                                .frame(width: 9, height: 1.4)
                            Capsule()
                                .fill(AppColors.accentGold.opacity(0.55))
                                .frame(width: 7, height: 1.4)
                            Capsule()
                                .fill(AppColors.accentGold.opacity(0.35))
                                .frame(width: 5, height: 1.4)
                        }
                        .padding(.top, 5)
                    }
                    .frame(width: 16, height: 20)
                    .offset(x: 2, y: 0)
            }
            .frame(width: 26, height: 22)

            Image(systemName: "pencil")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.accentAmber)
                .rotationEffect(.degrees(18))
                .offset(x: 5, y: 4)
        }
        .frame(width: 30, height: 26)
        .accessibilityHidden(true)
    }
}


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

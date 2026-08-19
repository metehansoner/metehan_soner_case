import SwiftUI


struct FeaturedRow: View {


    var isWordBasketLocked: Bool

    var hasCustomDecks: Bool
    var onMix: () -> Void
    var onWordBasket: () -> Void
    var onCustomDecks: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
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
        .padding(.bottom, 6)
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

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                icon
                    .overlay(alignment: .topTrailing) {
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.textOnAmber)
                                .frame(width: 18, height: 18)
                                .background(Circle().fill(AppColors.accentAmber))
                                .offset(x: 10, y: -8)
                        }
                    }

                Text(title)
                    .font(AppFont.display(13.5, weight: .semibold))
                    .appTracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textCream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .opacity(isLocked ? 0.82 : 1)
            .frame(maxWidth: .infinity)
            .frame(height: 98)
            .background { chrome }
            .shadow(color: accent.opacity(0.32), radius: 9, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private var icon: some View {
        switch style {
        case .mix:
            MixIcon()
        case .wordBasket:
            WordsIcon()
        case .customDeck:
            CustomDeckIcon()
        }
    }

    private var accent: Color {
        switch style {
        case .mix: Color(hex: 0x4EC4BF)
        case .wordBasket: AppColors.accentAmber
        case .customDeck: AppColors.accentGold
        }
    }

    private var chrome: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(background)
            .overlay {
                if style == .customDeck {
                    StripedFill()
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [accent.opacity(0.95), accent.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    .padding(1)
            }
    }

    private var background: AnyShapeStyle {
        switch style {
        case .mix:
            AnyShapeStyle(
                EllipticalGradient(
                    colors: [Color(hex: 0x4A8F8C), Color(hex: 0x1A3332), Color(hex: 0x101C1B)],
                    center: UnitPoint(x: 0.5, y: 0.28),
                    startRadiusFraction: 0,
                    endRadiusFraction: 0.9
                )
            )
        case .wordBasket:
            AnyShapeStyle(
                LinearGradient(
                    colors: [Color(hex: 0x6A2A28), AppColors.bgVelvetDeep, AppColors.surfaceCard],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .customDeck:
            AnyShapeStyle(
                LinearGradient(
                    colors: [AppColors.surfaceCardRaised, AppColors.surfaceCard],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}


private struct StripedFill: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 11
            var x: CGFloat = -size.height
            while x < size.width + size.height {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height + 5, y: size.height))
                path.addLine(to: CGPoint(x: x + 5, y: 0))
                path.closeSubpath()
                context.fill(path, with: .color(AppColors.accentGold.opacity(0.07)))
                x += step
            }
        }
        .allowsHitTesting(false)
    }
}


private struct MixIcon: View {
    var body: some View {
        ZStack {
            mixCard(fill: AppColors.accentTeal, rotation: -18, x: -11)
            mixCard(fill: AppColors.accentAmber, rotation: 18, x: 11)
            mixCard(fill: AppColors.surfacePoster, rotation: 0, x: 0)
        }
        .frame(width: 46, height: 36)
        .accessibilityHidden(true)
    }

    private func mixCard(fill: Color, rotation: Double, x: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(fill)
            .frame(width: 20, height: 28)
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(AppColors.accentGold.opacity(0.55), lineWidth: 1)
            }
            .rotationEffect(.degrees(rotation))
            .offset(x: x)
            .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
    }
}


private struct WordsIcon: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(AppColors.surfacePoster)
                .overlay {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(AppColors.accentGold, lineWidth: 1.2)
                }
                .overlay(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3.5) {
                        Capsule().fill(AppColors.textOnPoster.opacity(0.78)).frame(width: 18, height: 2.2)
                        Capsule().fill(AppColors.textOnPoster.opacity(0.5)).frame(width: 14, height: 2.2)
                        Capsule().fill(AppColors.textOnPoster.opacity(0.32)).frame(width: 10, height: 2.2)
                    }
                    .padding(.top, 8)
                    .padding(.leading, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(width: 26, height: 32)

            Image(systemName: "pencil")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppColors.accentAmber)
                .rotationEffect(.degrees(22))
                .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
                .offset(x: 6, y: 5)
        }
        .frame(width: 40, height: 38)
        .accessibilityHidden(true)
    }
}


private struct CustomDeckIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(AppColors.surfaceCardRaised)
                .overlay {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(AppColors.accentGold, lineWidth: 1.4)
                }
                .frame(width: 24, height: 32)

            Image(systemName: "plus")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(AppColors.textOnAmber)
                .frame(width: 18, height: 18)
                .background(Circle().fill(AppColors.accentAmber))
                .offset(x: 11, y: 12)
        }
        .frame(width: 40, height: 36)
        .accessibilityHidden(true)
    }
}

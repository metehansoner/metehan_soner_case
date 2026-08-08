import SwiftUI

/// Oyundaki gerçek duruş: alında **yatay** telefon. Nasıl Oynanır / onboarding
/// diyagramlarında dikey siluet yerine bunu kullanıyoruz.
struct LandscapeDemoPhone<Overlay: View>: View {
    var rim: Color = AppColors.accentGold
    var width: CGFloat = 132
    @ViewBuilder var overlay: () -> Overlay

    private var height: CGFloat { width * 0.48 }
    private var bezel: CGFloat { max(3.2, width * 0.028) }
    private var outerRadius: CGFloat { width * 0.14 }
    private var screenRadius: CGFloat { outerRadius - bezel * 0.55 }

    var body: some View {
        ZStack {
            // Gövde
            RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x2A221C),
                            Color(hex: 0x14100D),
                            Color(hex: 0x1C1612)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    rim.opacity(0.95),
                                    rim.opacity(0.35),
                                    rim.opacity(0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.6
                        )
                }

            // Ses / güç düğmeleri
            HStack {
                VStack(spacing: 5) {
                    Capsule().fill(Color(hex: 0x3A3028)).frame(width: 2.2, height: height * 0.12)
                    Capsule().fill(Color(hex: 0x3A3028)).frame(width: 2.2, height: height * 0.18)
                    Capsule().fill(Color(hex: 0x3A3028)).frame(width: 2.2, height: height * 0.18)
                }
                .offset(x: -1)
                Spacer(minLength: 0)
                Capsule()
                    .fill(Color(hex: 0x3A3028))
                    .frame(width: 2.2, height: height * 0.22)
                    .offset(x: 1)
            }
            .padding(.horizontal, 1)
            .frame(height: height * 0.7)

            // Ekran
            RoundedRectangle(cornerRadius: screenRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.surfacePoster,
                            Color(hex: 0xE8D9BE)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    // Film-kart hissi: hafif vignette
                    RoundedRectangle(cornerRadius: screenRadius, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.12), lineWidth: 0.8)
                }
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color(hex: 0x100C0A))
                        .frame(width: width * 0.22, height: height * 0.09)
                        .padding(.top, height * 0.07)
                }
                .overlay(alignment: .bottom) {
                    Capsule()
                        .fill(Color.black.opacity(0.18))
                        .frame(width: width * 0.16, height: 2.4)
                        .padding(.bottom, height * 0.08)
                }
                .overlay {
                    overlay()
                }
                .padding(bezel)
        }
        .frame(width: width, height: height)
        .shadow(color: rim.opacity(0.38), radius: 14, y: 6)
        .shadow(color: .black.opacity(0.45), radius: 10, y: 8)
    }
}

extension LandscapeDemoPhone where Overlay == EmptyView {
    init(rim: Color = AppColors.accentGold, width: CGFloat = 132) {
        self.rim = rim
        self.width = width
        self.overlay = { EmptyView() }
    }
}

/// Öne eğ = DOĞRU, arkaya eğ = PAS — iki yatay telefon.
struct TiltAnswerDiagram: View {
    var showsHints: Bool = false

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        HStack(spacing: showsHints ? 12 : 20) {
            phoneColumn(
                pitch: -30,
                color: AppColors.stateCorrect,
                systemImage: "arrow.down",
                label: l10n.t("game.stamp.correct"),
                hint: showsHints ? l10n.t("onboarding.zone.tiltForward") : nil
            )
            phoneColumn(
                pitch: 30,
                color: AppColors.stateSkip,
                systemImage: "arrow.up",
                label: l10n.t("game.stamp.skip"),
                hint: showsHints ? l10n.t("onboarding.zone.tiltBack") : nil
            )
        }
        .frame(maxWidth: .infinity)
        .environment(\.layoutDirection, .leftToRight)
    }

    private func phoneColumn(
        pitch: Double,
        color: Color,
        systemImage: String,
        label: String,
        hint: String?
    ) -> some View {
        VStack(spacing: 14) {
            LandscapeDemoPhone(rim: color, width: showsHints ? 138 : 146) {
                Image(systemName: systemImage)
                    .font(.system(size: showsHints ? 26 : 28, weight: .bold))
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(0.35), radius: 4)
            }
            .rotation3DEffect(
                .degrees(pitch),
                axis: (x: 1, y: 0.05, z: 0),
                anchor: .center,
                perspective: 0.55
            )
            .padding(.vertical, 10)

            VStack(spacing: 3) {
                Text(label)
                    .font(AppFont.display(13, weight: .semibold))
                    .appTracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(color)

                if let hint {
                    Text(hint)
                        .font(AppFont.ui(8.5))
                        .appTracking(1.4)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.textMuted)
                }
            }
        }
    }
}

import SwiftUI


struct MarqueeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Surface(configuration: configuration)
    }

    private struct Surface: View {
        let configuration: MarqueeButtonStyle.Configuration

        @Environment(\.isEnabled) private var isEnabled

        private var isPressed: Bool { configuration.isPressed && isEnabled }
        private static let lip: CGFloat = 3

        var body: some View {
            configuration.label
                .textStyle(.buttonLabel)
                .foregroundStyle(isEnabled ? AppColors.btnPrimaryText : AppColors.btnDisabledText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .padding(.horizontal, 28)
                .offset(y: isPressed ? Self.lip / 2 : 0)
                .background {
                    ZStack {


                        if isEnabled {
                            Capsule().fill(AppColors.accentAmberDeep)
                        }
                        Capsule()
                            .fill(isEnabled ? AppColors.btnPrimaryBg : AppColors.btnDisabledBg)
                            .padding(.bottom, isEnabled && !isPressed ? Self.lip : 0)
                    }
                    .overlay {
                        BulbFrame(countPerEdge: 5, isLit: isEnabled)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 3)
                    }
                    .shadow(
                        color: isEnabled ? AppColors.accentAmber.opacity(0.42) : .clear,
                        radius: 11
                    )
                }
                .scaleEffect(isPressed ? 0.97 : 1)
                .animation(.easeOut(duration: 0.12), value: isPressed)

                .onChange(of: isPressed) { _, pressed in
                    guard pressed else { return }
                    Haptics.prepareImpact()
                    SoundService.buttonTap()
                }
        }
    }
}


struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Surface(configuration: configuration)
    }

    private struct Surface: View {
        let configuration: SecondaryButtonStyle.Configuration

        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .textStyle(.buttonLabel)
                .foregroundStyle(isEnabled ? AppColors.btnSecondaryText : AppColors.btnDisabledText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .padding(.horizontal, 28)
                .background {
                    Capsule()
                        .fill(AppColors.btnSecondaryBg.opacity(0.55))
                        .overlay {
                            Capsule().strokeBorder(
                                isEnabled
                                    ? AppColors.btnSecondaryBorder
                                    : AppColors.stateLocked.opacity(0.5),
                                lineWidth: 1.5
                            )
                        }
                }
                .opacity(configuration.isPressed && isEnabled ? 0.82 : 1)
                .onChange(of: configuration.isPressed) { _, pressed in
                    guard pressed, isEnabled else { return }
                    Haptics.prepareImpact()
                    SoundService.buttonTap()
                }
        }
    }
}


struct BackNavButton: View {
    var tint: Color = AppColors.accentGold
    var accessibilityLabel: String
    var action: () -> Void

    static let hitSide: CGFloat = 52

    var body: some View {
        Button {
            Haptics.secondaryButton()
            action()
        } label: {
            Image(systemName: "chevron.left")
                .flipsForRightToLeftLayoutDirection(true)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: Self.hitSide, height: Self.hitSide)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

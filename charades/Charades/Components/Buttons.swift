import SwiftUI

/// Birincil buton — 01-tasarim-sistemi.md §4 "Marquee Button".
///
/// Alt kenardaki 3px `accentAmberDeep` şerit basılınca kayboluyor: amber yüzey
/// aşağı doğru büyüyüp şeridi yutuyor, etiket onunla birlikte iniyor. Fiziksel
/// tuş hissi bu iki hareketten geliyor, tek başına `scaleEffect` vermiyor.
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
                        // Şerit yalnızca basılabilir hâlde çiziliyor: disabled buton
                        // fiziksel tuş gibi görünmemeli.
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
                // §4.1: prepare parmak *inince*; ses de aynı anda (tap-down).
                .onChange(of: isPressed) { _, pressed in
                    guard pressed else { return }
                    Haptics.prepareImpact()
                    SoundService.buttonTap()
                }
        }
    }
}

/// İkincil buton — §4. Şeffaf zemin, 1.5px `accentGold` kenar, içeride hafif dolgu.
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

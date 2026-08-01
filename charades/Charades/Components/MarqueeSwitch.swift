import SwiftUI

/// 01-tasarim-sistemi.md §4 "Marquee Switch": native `Toggle` yerine iki
/// segmentli kapsül. Aktif segment `accentAmber` zemin + `textOnAmber`.
struct MarqueeSwitch: View {
    @Binding var isOn: Bool

    @Bindable private var l10n = LocalizationManager.shared
    @Namespace private var indicator

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            segment(l10n.t("common.off"), isActive: !isOn)
            segment(l10n.t("common.on"), isActive: isOn)
        }
        .padding(2)
        .background {
            Capsule()
                .fill(AppColors.surfaceCard)
                .overlay {
                    Capsule().strokeBorder(AppColors.accentGold.opacity(0.35), lineWidth: 1)
                }
        }
        // Dar bir satırda sıkışırsa `KAPALI` iki satıra bölünüyor; anahtar
        // doğal genişliğini isteyip yeri başlıktan alsın.
        .fixedSize()
        .contentShape(Capsule())
        .onTapGesture {
            // Reduce Motion'da amber kapsül kaymıyor, doğrudan diğer segmentte
            // beliriyor; durum yine görünüyor.
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.18)) { isOn.toggle() }
        }
        .accessibilityElement(children: .ignore)
        // Etiketi satırın başlığı veriyor (`SettingsRow` öğeleri birleştiriyor);
        // anahtarın kendi işi durumu söylemek. `.isToggle` olmadan VoiceOver
        // "düğme" deyip açık/kapalı ayrımını jest ipucuna bırakıyordu.
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? l10n.t("common.on") : l10n.t("common.off"))
    }

    private func segment(_ title: String, isActive: Bool) -> some View {
        Text(title)
            .textStyle(.sectionLabel)
            .lineLimit(1)
            .foregroundStyle(isActive ? AppColors.textOnAmber : AppColors.textMuted)
            .padding(.vertical, 7)
            .padding(.horizontal, 14)
            .background {
                if isActive {
                    Capsule()
                        .fill(AppColors.accentAmber)
                        .matchedGeometryEffect(id: "activeSegment", in: indicator)
                }
            }
    }
}

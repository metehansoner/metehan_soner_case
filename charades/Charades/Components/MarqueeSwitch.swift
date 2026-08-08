import SwiftUI


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


        .fixedSize()
        .contentShape(Capsule())
        .onTapGesture {


            withAnimation(reduceMotion ? nil : .snappy(duration: 0.18)) { isOn.toggle() }
        }
        .accessibilityElement(children: .ignore)


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

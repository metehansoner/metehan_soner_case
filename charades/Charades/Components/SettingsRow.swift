import SwiftUI


struct SettingsRow<Control: View>: View {


    enum ControlPlacement {
        case trailing
        case below
    }

    let icon: String
    let title: String
    var subtitle: String?


    var action: (() -> Void)?
    var isEnabled = true
    var placement: ControlPlacement = .trailing
    @ViewBuilder var control: Control

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if let action {
            Button {
                Haptics.secondaryButton()
                action()
            } label: {
                content
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        } else {


            content.accessibilityElement(children: .combine)
        }
    }


    private var stacksControl: Bool {
        placement == .below || typeSize.isAccessibilitySize
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isEnabled ? AppColors.accentGold : AppColors.stateLocked)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .textStyle(.bodyStrong)
                        .foregroundStyle(isEnabled ? AppColors.textCream : AppColors.stateLocked)

                    if let subtitle {
                        Text(subtitle)
                            .textStyle(.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !stacksControl {
                    control
                }
            }

            if stacksControl {
                control
                    .frame(maxWidth: .infinity, alignment: typeSize.isAccessibilitySize ? .leading : .center)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}


struct SettingsDisclosure: View {
    var value: String?

    var body: some View {
        HStack(spacing: 8) {
            if let value {
                Text(value)
                    .textStyle(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textMuted)
                .flipsForRightToLeftLayoutDirection(true)


                .accessibilityHidden(true)
        }
    }
}


struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .textStyle(.sectionLabel)
                .foregroundStyle(AppColors.accentGold)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.surfaceCard.opacity(0.75))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(AppColors.accentGold.opacity(0.22), lineWidth: 1)
                    }
            }
        }
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppColors.accentGold.opacity(0.15))
            .frame(height: 1)
            .padding(.leading, 52)
    }
}


struct SettingsSegment<Option: Hashable>: View {
    let options: [Option]
    let title: (Option) -> String
    @Binding var selection: Option

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option
                Button {
                    guard !isSelected else { return }
                    Haptics.selection()
                    selection = option
                } label: {
                    Text(title(option))
                        .font(AppFont.ui(10.5, weight: .semibold))
                        .appTracking(1.4)
                        .textCase(.uppercase)
                        .foregroundStyle(isSelected ? AppColors.textOnAmber : AppColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            Capsule().fill(isSelected ? AppColors.accentAmber : .clear)
                        }

                        .frame(minHeight: 38)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(3)
        .background {
            Capsule()
                .fill(AppColors.bgFilmBlack.opacity(0.5))
                .overlay {
                    Capsule().strokeBorder(AppColors.accentGold.opacity(0.3), lineWidth: 1)
                }
        }
    }
}


struct SettingsStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let format: (Int) -> String

    var body: some View {
        HStack(spacing: 6) {
            button(systemImage: "minus", delta: -step)

            Text(format(value))
                .font(AppFont.display(16, weight: .bold, scales: .body))
                .monospacedDigit()
                .foregroundStyle(AppColors.textCream)
                .frame(minWidth: 52)

            button(systemImage: "plus", delta: step)
        }


        .accessibilityElement(children: .ignore)
        .accessibilityValue(format(value))
        .accessibilityAdjustableAction { direction in
            let delta = direction == .increment ? step : -step
            guard range.contains(value + delta) else {
                Haptics.stepperLimit()
                return
            }
            Haptics.selection()
            value += delta
        }
    }

    private func button(systemImage: String, delta: Int) -> some View {
        let isAvailable = range.contains(value + delta)
        return Button {
            guard isAvailable else {
                Haptics.stepperLimit()
                return
            }
            Haptics.selection()
            value += delta
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isAvailable ? AppColors.accentAmber : AppColors.stateLocked)
                .frame(width: 32, height: 32)
                .background {
                    Circle()
                        .fill(AppColors.bgFilmBlack.opacity(0.55))
                        .overlay {
                            Circle().strokeBorder(
                                (isAvailable ? AppColors.accentGold : AppColors.stateLocked).opacity(0.5),
                                lineWidth: 1
                            )
                        }
                }


                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

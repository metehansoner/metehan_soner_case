import SwiftUI

/// Sticky bottom bar: PLAY | summary
struct PlayBar: View {
    let playTitle: String
    let summary: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            guard enabled else { return }
            action()
        }) {
            HStack(spacing: 0) {
                Text(playTitle)
                    .font(AppFont.ui(18, weight: .bold))
                    .foregroundStyle(enabled ? AppColors.textOnLight : AppColors.btnDisabledText)
                    .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(AppColors.textOnLight.opacity(0.25))
                    .frame(width: 1, height: 22)

                Text(summary)
                    .font(AppFont.ui(15, weight: .semibold))
                    .foregroundStyle(enabled ? AppColors.textOnLight.opacity(0.85) : AppColors.btnDisabledText)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 18)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 22,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 22,
                    style: .continuous
                )
                .fill(enabled ? AppColors.btnPrimaryBg : AppColors.btnDisabledBg)
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct ScreenChromeHeader: View {
    let title: String
    var onBack: (() -> Void)?
    var onSettings: (() -> Void)?

    var body: some View {
        HStack {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                }
            } else {
                Color.clear.frame(width: 40, height: 40)
            }

            Spacer()
            ScreenTitle(text: title)
            Spacer()

            if let onSettings {
                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                }
            } else {
                Color.clear.frame(width: 40, height: 40)
            }
        }
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(AppFont.ui(20, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
            Text(subtitle)
                .font(AppFont.ui(14))
                .foregroundStyle(AppColors.textSecondary)
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.surfaceCard)
        )
    }
}

struct StepperControl: View {
    let valueText: String
    var canDecrement: Bool
    var canIncrement: Bool
    var onDecrement: () -> Void
    var onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 28) {
            circleButton(systemName: "minus", enabled: canDecrement, action: onDecrement)
            Text(valueText)
                .font(AppFont.display(28, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(minWidth: 72)
            circleButton(systemName: "plus", enabled: canIncrement, action: onIncrement)
        }
        .frame(maxWidth: .infinity)
    }

    private func circleButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            Haptics.selection()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(enabled ? AppColors.textPrimary : AppColors.stateLocked)
                .frame(width: 44, height: 44)
                .background(Circle().fill(AppColors.surfaceCardElevated))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

import SwiftUI

/// Sticky bottom CTA: dominant PLAY + compact count chip
struct PlayBar: View {
    let playTitle: String
    let count: Int
    let countSystemImage: String
    var countAccessibilityLabel: String? = nil
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            guard enabled else { return }
            action()
        }) {
            HStack(spacing: 12) {
                Text(playTitle)
                    .font(AppFont.display(24, weight: .black))
                    .foregroundStyle(enabled ? AppColors.btnPrimaryText : AppColors.btnDisabledText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 22)

                HStack(spacing: 6) {
                    Image(systemName: countSystemImage)
                        .font(.system(size: 13, weight: .bold))
                    Text("\(count)")
                        .font(AppFont.display(20, weight: .bold))
                        .monospacedDigit()
                }
                .foregroundStyle(enabled ? AppColors.textPrimary : AppColors.btnDisabledText)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(enabled ? AppColors.surfaceCard : AppColors.btnDisabledBg.opacity(0.55))
                )
                .accessibilityLabel(countAccessibilityLabel ?? "\(count)")
                .padding(.trailing, 10)
            }
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(enabled ? AppColors.btnPrimaryBg : AppColors.btnDisabledBg)
                    .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
                    .shadow(color: AppColors.accentYellow.opacity(enabled ? 0.35 : 0), radius: 10, y: 0)
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                colors: [AppColors.bgPrimary.opacity(0), AppColors.bgPrimary.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        )
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
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer()
            ScreenTitle(text: title)
            Spacer()

            if let onSettings {
                HeaderCircleIconButton(systemName: "gearshape.fill", size: 44, action: onSettings)
            } else {
                Color.clear.frame(width: 44, height: 44)
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
                .font(AppFont.ui(14, weight: .bold))
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

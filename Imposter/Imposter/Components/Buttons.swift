import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.ui(17, weight: .bold))
            .foregroundStyle(enabled ? AppColors.btnPrimaryText : AppColors.btnDisabledText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(enabled ? AppColors.btnPrimaryBg : AppColors.btnDisabledBg)
                    .shadow(color: enabled ? AppColors.accentCyan.opacity(0.35) : .clear, radius: 10, y: 2)
            )
            .opacity(configuration.isPressed && enabled ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && enabled ? 0.98 : 1)
    }
}

struct SecondaryCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.ui(17, weight: .bold))
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(AppColors.btnSecondaryBg)
                    .overlay(
                        Capsule()
                            .stroke(AppColors.accentCyan.opacity(0.5), lineWidth: 1.5)
                    )
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct ScreenTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppFont.display(28, weight: .bold))
            .foregroundStyle(AppColors.textPrimary)
    }
}

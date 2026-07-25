import SwiftUI

/// Centered exit confirmation — matches Fakeit-style dialog.
struct ExitGameConfirmOverlay: View {
    var onCancel: () -> Void
    var onConfirm: () -> Void

    @Bindable private var l10n = LocalizationManager.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    Haptics.light()
                    onCancel()
                }

            VStack(spacing: 14) {
                Text(l10n.t("drawing.exitTitle"))
                    .font(AppFont.display(26, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(l10n.t("drawing.exitBody"))
                    .font(AppFont.ui(15, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button {
                        Haptics.light()
                        onCancel()
                    } label: {
                        Text(l10n.t("common.cancel"))
                            .font(AppFont.display(17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        Haptics.medium()
                        onConfirm()
                    } label: {
                        Text(l10n.t("drawing.exitConfirm"))
                            .font(AppFont.display(17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(AppColors.stateDanger))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(hex: 0x2A2A2E))
            )
            .padding(.horizontal, 28)
        }
    }
}

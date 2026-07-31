import SwiftUI

struct PauseOverlay: View {
    var onResume: () -> Void
    var onVote: (() -> Void)? = nil

    @Bindable private var l10n = LocalizationManager.shared
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(AppColors.accentCyan.opacity(0.18))
                        .frame(width: 110, height: 110)

                    Circle()
                        .stroke(AppColors.accentCyan.opacity(0.45), lineWidth: 2)
                        .frame(width: 110, height: 110)

                    Image(systemName: "pause.fill")
                        .font(.system(size: 42, weight: .black))
                        .foregroundStyle(AppColors.accentCyan)
                }
                .shadow(color: AppColors.accentCyan.opacity(0.35), radius: 18, y: 4)

                VStack(spacing: 8) {
                    Text(l10n.t("round.paused"))
                        .font(AppFont.display(28, weight: .black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(l10n.t("round.tapToContinue"))
                        .font(AppFont.ui(15, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    Button(action: resume) {
                        Text(l10n.t("round.resume"))
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    if let onVote {
                        Button {
                            Haptics.medium()
                            onVote()
                        } label: {
                            Text(l10n.t("round.vote"))
                        }
                        .buttonStyle(SecondaryCapsuleButtonStyle())
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 28)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(AppColors.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(AppColors.accentCyan.opacity(0.28), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
            )
            .padding(.horizontal, 28)
            .scaleEffect(appear ? 1 : 0.92)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                appear = true
            }
        }
    }

    private func resume() {
        Haptics.medium()
        onResume()
    }
}

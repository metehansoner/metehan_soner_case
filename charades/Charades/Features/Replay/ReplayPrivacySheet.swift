import SwiftUI


struct ReplayPrivacySheet: View {
    var onContinue: () -> Void
    var onCancel: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        SheetScaffold(title: l10n.t("replay.privacy.title"), onClose: onCancel) {
            VStack(spacing: 18) {
                lens

                Text(l10n.t("replay.privacy.body"))
                    .font(AppFont.ui(14))
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(AppColors.textCream)

                Text(l10n.t("replay.privacy.note"))
                    .font(AppFont.ui(11.5))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(AppColors.textMuted)

                Spacer(minLength: 0)

                Button(l10n.t("replay.privacy.continue")) {
                    Haptics.primaryButton()
                    onContinue()
                }
                .buttonStyle(MarqueeButtonStyle())

                Button(l10n.t("common.cancel")) {
                    Haptics.secondaryButton()
                    onCancel()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .padding(.bottom, 22)
        }


        .presentationDetents([.fraction(0.58)])
    }


    private var lens: some View {
        ZStack {
            Circle()
                .strokeBorder(AppColors.accentGold.opacity(0.4), lineWidth: 1)
                .frame(width: 84, height: 84)

            Circle()
                .fill(AppColors.surfaceCardRaised)
                .frame(width: 62, height: 62)

            Image(systemName: "person.2.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(AppColors.accentAmber)
        }
        .padding(.top, 4)
    }
}

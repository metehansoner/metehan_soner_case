import SwiftUI


struct LapseNoticeCard: View {
    var onSeeTicket: () -> Void
    var onDismiss: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "ticket")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.accentBrass)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(l10n.t("paywall.lapse.title"))
                    .font(AppFont.display(14, weight: .semibold))
                    .appTracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textCream)

                Text(l10n.t("paywall.lapse.body"))
                    .font(AppFont.ui(11.5))
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    Haptics.secondaryButton()
                    onSeeTicket()
                } label: {
                    Text(l10n.t("paywall.lapse.cta"))
                        .font(AppFont.ui(11.5, weight: .semibold))
                        .foregroundStyle(AppColors.accentAmber)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }

            Button {
                Haptics.secondaryButton()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.textMuted)
                    .frame(width: 26, height: 26)
                    .tapTarget()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.t("common.close"))
        }
        .padding(13)
        .background {
            RoundedRectangle(cornerRadius: 13)
                .fill(AppColors.surfaceCard.opacity(0.9))
                .overlay {
                    RoundedRectangle(cornerRadius: 13)
                        .strokeBorder(AppColors.accentBrass.opacity(0.45), lineWidth: 1)
                }
        }
    }
}

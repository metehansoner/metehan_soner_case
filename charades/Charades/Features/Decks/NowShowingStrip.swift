import SwiftUI


struct NowShowingStrip: View {
    let deck: DeckDef
    var onTap: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                poster

                VStack(alignment: .leading, spacing: 3) {
                    Text(l10n.t("nowShowing.badge"))
                        .font(AppFont.ui(9.5, weight: .bold))
                        .appTracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.accentAmber)

                    Text(l10n.t(deck.titleKey))
                        .font(AppFont.accent(18, weight: .black))
                        .foregroundStyle(AppColors.textCream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                countdown
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.surfaceCardRaised.opacity(0.98),
                                AppColors.surfaceCard.opacity(0.88),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(AppColors.accentAmber.opacity(0.55), lineWidth: 1.4)
                    }
                    .shadow(color: AppColors.accentAmber.opacity(0.22), radius: 14, y: 4)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var poster: some View {
        Image(deck.imageName)
            .resizable()
            .scaledToFit()
            .padding(7)
            .frame(width: 58, height: 76)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(deck.section.artGradient)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(AppColors.accentGold.opacity(0.85), lineWidth: 1.2)
                    }
            }
            .shadow(color: .black.opacity(0.35), radius: 5, y: 2)
    }


    private var countdown: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .trailing, spacing: 2) {
                Text(Self.remainingText(at: context.date))
                    .font(AppFont.display(17, weight: .semibold))
                    .appTracking(0.6)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.accentGold)

                Text(l10n.t("nowShowing.remaining"))
                    .font(AppFont.ui(8, weight: .medium))
                    .appTracking(1.3)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textMuted)
            }
        }
    }

    static func remainingText(at date: Date, calendar: Calendar = .current) -> String {
        guard let midnight = calendar.nextDate(
            after: date,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) else { return "--:--:--" }

        let seconds = max(0, Int(midnight.timeIntervalSince(date)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}

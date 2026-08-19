import SwiftUI


struct NowShowingStrip: View {
    let deck: DeckDef
    var onTap: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                poster

                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.t("nowShowing.badge"))
                        .font(AppFont.display(11, weight: .semibold))
                        .appTracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.accentAmber)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(l10n.t(deck.titleKey))
                        .font(AppFont.accent(20, weight: .black))
                        .foregroundStyle(AppColors.textCream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                countdown
            }
            .padding(.leading, 10)
            .padding(.trailing, 12)
            .padding(.vertical, 10)
            .background { chrome }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var poster: some View {
        Image(deck.imageName)
            .resizable()
            .scaledToFit()
            .padding(7)
            .frame(width: 56, height: 74)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(deck.section.artGradient)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(AppColors.accentGold.opacity(0.55), lineWidth: 1.15)
                    }
            }
    }

    private var countdown: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .trailing, spacing: 2) {
                Text(Self.remainingText(at: context.date))
                    .font(AppFont.display(16, weight: .semibold))
                    .appTracking(0.3)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.textCream)

                Text(l10n.t("nowShowing.remaining"))
                    .font(AppFont.display(9, weight: .semibold))
                    .appTracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.accentGold)
            }
        }
    }

    private var chrome: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [AppColors.surfaceCardRaised, AppColors.surfaceCard],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppColors.accentAmber.opacity(0.7), lineWidth: 1.15)
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

import SwiftUI

/// "ŞİMDİ VİZYONDA" şeridi — 02-ekran-akisi.md §4 (ekran 4, madde 3).
///
/// Günlük bedava desteyi geri sayımla duyuruyor. Premium kullanıcıda gizli:
/// zaten her deste açık, şerit ona bir şey söylemiyor. Gün dönümü cihazın
/// yerel gece yarısı (§09 §8).
struct NowShowingStrip: View {
    let deck: DeckDef
    var onTap: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 11) {
                poster

                VStack(alignment: .leading, spacing: 1) {
                    Text(l10n.t("nowShowing.badge"))
                        .font(AppFont.ui(8, weight: .bold))
                        .appTracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.accentAmber)

                    Text(l10n.t(deck.titleKey))
                        .font(AppFont.accent(14, weight: .black))
                        .foregroundStyle(AppColors.textCream)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                countdown
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 11)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.surfaceCardRaised.opacity(0.96),
                                AppColors.surfaceCard.opacity(0.82),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 11)
                            .strokeBorder(AppColors.accentAmber.opacity(0.42), lineWidth: 1)
                    }
                    .shadow(color: AppColors.accentAmber.opacity(0.1), radius: 10)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var poster: some View {
        Image(deck.imageName)
            .resizable()
            .scaledToFit()
            .padding(4)
            .frame(width: 32, height: 42)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(deck.section.artGradient)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(AppColors.accentGold, lineWidth: 1)
                    }
            }
    }

    /// Saniye başı yenilenen tek öğe bu; şeridin geri kalanı yeniden çizilmiyor.
    private var countdown: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .trailing, spacing: 0) {
                Text(Self.remainingText(at: context.date))
                    .font(AppFont.display(14, weight: .semibold))
                    .appTracking(0.6)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.accentGold)

                Text(l10n.t("nowShowing.remaining"))
                    .font(AppFont.ui(7, weight: .medium))
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

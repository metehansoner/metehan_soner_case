import SwiftUI

/// Altın bilet kartı — 06-ayarlar-ve-lokalizasyon.md §1 Grup 4.
///
/// Yalnızca premium kullanıcıda, HESAP grubunun **üstünde**. Gerekçe dokümanda
/// tek cümle: ödediği şeyi görmesi iptal oranını düşürüyor.
struct SubscriptionCard: View {
    let renewalDate: Date?

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColors.textOnAmber)
                .frame(width: 40, height: 40)
                .background {
                    Circle().fill(AppColors.accentAmber)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(l10n.t("settings.ticket.active"))
                    .textStyle(.sectionLabel)
                    .foregroundStyle(AppColors.accentGold)

                if let renewal {
                    Text(renewal)
                        .textStyle(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.accentGold.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppColors.accentGold.opacity(0.55), lineWidth: 1)
                }
        }
    }

    /// Tarih yoksa satır hiç yazılmıyor: "Yenileme: —" bilgi vermiyor, sadece
    /// bir şeyin bozuk olduğunu düşündürüyor.
    private var renewal: String? {
        guard let renewalDate else { return nil }
        let formatted = renewalDate.formatted(
            .dateTime.day().month(.wide).year().locale(Locale(identifier: l10n.localeCode))
        )
        return l10n.t("settings.ticket.renews", ["date": formatted])
    }
}

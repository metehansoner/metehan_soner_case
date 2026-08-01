import SwiftUI

/// Mod Seçimi kartı — `ornek-ekranlar.html` `.mode` kuralları (ekran 10).
///
/// Kilit göstergesi § `09` §9: 5 premium modun sağ üstünde bilet ikonu + soluk
/// zemin, kilitli deste kartıyla **aynı dil** (§ `01` §4). İki farklı kilit
/// görseli kullanmak, kullanıcının "bu neden kapalı" sorusunu her ekranda
/// yeniden sormasına yol açıyor.
struct ModeCard: View {
    let mode: GameMode
    var isSelected: Bool
    var isLocked: Bool
    var action: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                emblem

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.t(mode.titleKey))
                        .font(AppFont.display(14.5, weight: .semibold))
                        .appTracking(1.7)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.textCream)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(l10n.t(mode.subtitleKey))
                        .font(AppFont.ui(10.5))
                        .foregroundStyle(AppColors.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)

                if isLocked {
                    ticketBadge
                }
            }
            .padding(.horizontal, isSelected ? 12 : 13)
            .padding(.vertical, isSelected ? 11 : 12)
            .background {
                RoundedRectangle(cornerRadius: 13)
                    .fill(
                        LinearGradient(
                            colors: isSelected
                                ? [Color(hex: 0x4A3016).opacity(0.8), Color(hex: 0x261A11).opacity(0.8)]
                                : [AppColors.surfaceCardRaised.opacity(0.9), AppColors.surfaceCard.opacity(0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 13).strokeBorder(
                            isSelected ? AppColors.accentAmber : AppColors.accentGold.opacity(0.24),
                            lineWidth: isSelected ? 2 : 1
                        )
                    }
                    .shadow(color: AppColors.accentAmber.opacity(isSelected ? 0.18 : 0), radius: 9, y: 4)
            }
            // Kilitli kart soluk ama okunur: § `01` §4 kilitli desteyle aynı
            // oran. Tamamen soldurmak "bozuk" hissi veriyor.
            .opacity(isLocked ? 0.72 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var emblem: some View {
        Image(systemName: mode.systemImage)
            .font(.system(size: 19, weight: .medium))
            .foregroundStyle(AppColors.accentAmber)
            .frame(width: 40, height: 40)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        RadialGradient(
                            colors: [AppColors.accentAmber.opacity(0.26), AppColors.bgFilmBlack.opacity(0.7)],
                            center: UnitPoint(x: 0.5, y: 0.35),
                            startRadius: 1,
                            endRadius: 30
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(AppColors.accentGold.opacity(0.4), lineWidth: 1)
                    }
            }
    }

    private var ticketBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 8, weight: .bold))
            Text(l10n.t("mode.locked.badge"))
                .font(AppFont.ui(8, weight: .bold))
                .appTracking(1.2)
                .textCase(.uppercase)
        }
        .foregroundStyle(AppColors.accentGold)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .overlay {
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(AppColors.accentGold.opacity(0.45), lineWidth: 1)
        }
    }

    private var accessibilityLabel: String {
        var parts = [l10n.t(mode.titleKey), l10n.t(mode.subtitleKey)]
        if isLocked { parts.append(l10n.t("mode.locked.badge")) }
        return parts.joined(separator: ", ")
    }
}

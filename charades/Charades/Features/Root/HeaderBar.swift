import SwiftUI

/// Ana ekran header'ı — 02-ekran-akisi.md §1 ve §4 (ekran 4).
///
/// Tab bar yok; ayarlar bu satırdaki dişliden sheet olarak açılıyor. Logo
/// boyutu sabit — kaydırınca küçülmez. VIP ve dişli her zaman erişilebilir.
struct HeaderBar: View {
    /// §1: makara ikonu **yalnızca** arşivde en az bir kayıt varken görünür.
    /// Boş bir arşive giden kalıcı buton header'ı gereksiz kalabalıklaştırıyor.
    var archiveCount: Int
    var isPremium: Bool

    var onTapVIP: () -> Void
    var onTapArchive: () -> Void
    var onTapSettings: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    /// Logo ortada duruyor, butonlar onun üstünde: makara ikonu belirince sağ
    /// küme genişliyor ve uzun dillerde plaka butonların altına giriyor. Geniş
    /// tarafın payı iki yana birden veriliyor ki logo ortada kalsın.
    private var sideInset: CGFloat { archiveCount > 0 ? 98 : 44 }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                logoPlaque
                    .padding(.horizontal, sideInset)

                HStack(spacing: 10) {
                    HeaderCircleIconButton(
                        systemName: isPremium ? "ticket.fill" : "ticket",
                        tint: isPremium ? AppColors.accentGold : AppColors.accentBrass,
                        accessibilityLabel: l10n.t(isPremium ? "header.vip.premium" : "header.vip"),
                        action: onTapVIP
                    )

                    Spacer(minLength: 0)

                    if archiveCount > 0 {
                        HeaderCircleIconButton(
                            systemName: "film.stack",
                            badge: archiveCount,
                            accessibilityLabel: l10n.t("header.archive"),
                            action: onTapArchive
                        )
                    }

                    HeaderCircleIconButton(
                        systemName: "gearshape.fill",
                        accessibilityLabel: l10n.t("header.settings"),
                        action: onTapSettings
                    )
                }
            }

            tagline
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    /// §4: logo Oswald Bold, çevresinde 14 ampul, sıralı yanıp sönme.
    private var logoPlaque: some View {
        Text(l10n.t("app.name"))
            .font(AppFont.display(34, weight: .bold))
            .appTracking(3.5)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textCream)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 22)
            .padding(.vertical, 5)
            .overlay {
                BulbFrame(countPerEdge: 7, diameter: 3.5, color: AppColors.accentAmber)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 1)
            }
            .accessibilityAddTraits(.isHeader)
    }

    /// §4: logonun altında ince altın çizgi + sabit alt başlık.
    private var tagline: some View {
        HStack(spacing: 8) {
            goldRule
            Text(l10n.t("app.tagline"))
                .textStyle(.sectionLabel)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize()
            goldRule
        }
        .frame(maxWidth: 260)
        .frame(height: 14)
    }

    private var goldRule: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, AppColors.accentGold.opacity(0.55)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

/// §1: 40pt daire, `surfaceCardRaised` zemin, 1px `accentGold` kenar,
/// ikon `accentBrass`.
struct HeaderCircleIconButton: View {
    var systemName: String
    var tint: Color = AppColors.accentBrass
    var badge: Int?
    var accessibilityLabel: String
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.secondaryButton()
            SoundService.buttonTap()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(AppColors.surfaceCardRaised)
                        .overlay {
                            Circle().strokeBorder(AppColors.accentGold.opacity(0.7), lineWidth: 1)
                        }
                }
                .overlay(alignment: .topTrailing) {
                    if let badge, badge > 0 {
                        Text(badge > 99 ? "99+" : "\(badge)")
                            .font(AppFont.ui(10, weight: .bold))
                            .foregroundStyle(AppColors.textOnAmber)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(AppColors.accentAmber))
                            .offset(x: 4, y: -2)
                    }
                }
                // Daire 40pt: header bandının yüksekliği buna göre kuruldu.
                // Dokunma alanı 44pt'ye açılıyor, görünen boyut değişmiyor.
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

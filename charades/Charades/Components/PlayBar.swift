import SwiftUI

/// Alt aksiyon barı — 02-ekran-akisi.md §1 ve §4 (madde 7).
///
/// Tab bar kaldırıldığı için ekranın altı sabit bir navigasyon öğesi değil:
/// seçim varken beliriyor, yokken tüm dikey alan ızgaraya kalıyor. Doğrudan
/// safe area'nın üzerinde oturuyor.
struct PlayBar: View {
    var deckCount: Int
    var cardCount: Int
    /// §09 §9: 2+ deste ile `OYNA` Mix demek ve Mix premium. Etiket ikinci
    /// deste seçildiği anda görünüyor — kullanıcı butona basmadan önce.
    var isMix: Bool
    var isPremium: Bool
    var isPlayEnabled: Bool
    var onPlay: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.display(13.5, weight: .semibold))
                    .appTracking(0.9)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textCream)

                Text(subtitle)
                    .font(AppFont.ui(9.5))
                    .appTracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(subtitleColor)
            }

            Spacer(minLength: 0)

            Button(l10n.t("common.play"), action: onPlay)
                .buttonStyle(MarqueeButtonStyle())
                .disabled(!isPlayEnabled)
                .fixedSize()
        }
        .padding(.horizontal, 18)
        .padding(.top, 13)
        .padding(.bottom, 8)
        .background {
            LinearGradient(
                colors: [
                    AppColors.surfaceCard.opacity(0.86),
                    AppColors.bgFilmBlack.opacity(0.99),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(AppColors.accentGold.opacity(0.34))
                    .frame(height: 1)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var title: String {
        if isMix {
            return l10n.t("playbar.mixReady")
        }
        return l10n.t("playbar.summary", count: deckCount)
    }

    private var subtitle: String {
        if !isPlayEnabled {
            return l10n.t("playbar.noContent")
        }
        if isMix, !isPremium {
            return "\(l10n.t("playbar.cards", count: cardCount)) · \(l10n.t("playbar.premium"))"
        }
        return l10n.t("playbar.cards", count: cardCount)
    }

    private var subtitleColor: Color {
        if !isPlayEnabled { return AppColors.stateWarning }
        if isMix, !isPremium { return AppColors.accentAmber }
        return AppColors.textMuted
    }
}

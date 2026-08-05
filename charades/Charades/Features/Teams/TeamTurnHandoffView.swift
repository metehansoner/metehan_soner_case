import SwiftUI

/// Perde Arası — 08-sinematik-detaylar.md §B2, faz tanımı § `09` §5.
///
/// Bu ekran zaten gerekliydi: telefon elden ele geçiyor. Düz "Sıra Kırmızı
/// Takımda" yerine eski sinemaların perde arası kartı giydirildi.
///
/// **Landscape** (§ `09` §1): telefon hâlâ yatay, yön burada değişmiyor.
/// Mockup portrait bir kart; yatayda aynı içerik iki sütuna açılıyor.
struct TeamTurnHandoffView: View {
    let match: TeamMatch
    let teamIndex: Int
    let player: String?
    let secondsLeft: Int
    var onReady: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    private var isSuddenDeath: Bool { match.isSuddenDeath }
    private var teamColor: Color { AppColors.team(teamIndex) }

    var body: some View {
        ZStack {
            VelvetBackground(showsCurtain: true)

            VStack(spacing: 14) {
                frame

                Button(l10n.t("teams.ready")) {
                    Haptics.primaryButton()
                    onReady()
                }
                .buttonStyle(MarqueeButtonStyle())
                .frame(maxWidth: 260)
            }
            .padding(.horizontal, 54)
            .padding(.vertical, 14)
        }
        .statusBarHidden()
    }

    // MARK: Kart

    private var frame: some View {
        HStack(spacing: 0) {
            title
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(AppColors.accentGold.opacity(0.3))
                .frame(width: 1)
                .padding(.vertical, 6)

            nextUp
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.surfaceCard.opacity(0.7))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSuddenDeath ? AppColors.stateSkip : AppColors.accentGold, lineWidth: 2)
                }
                // §B2: çerçevenin içinde, kenarlardan 12pt içeride iki ince çizgi.
                .overlay(alignment: .top) { innerRule.padding(.top, 7) }
                .overlay(alignment: .bottom) { innerRule.padding(.bottom, 7) }
        }
    }

    private var innerRule: some View {
        Rectangle()
            .fill(AppColors.accentGold.opacity(0.35))
            .frame(height: 1)
            .padding(.horizontal, 12)
    }

    private var title: some View {
        VStack(spacing: 8) {
            Text(l10n.t(isSuddenDeath ? "teams.suddenDeath.title" : "teams.intermission.title"))
                .font(AppFont.display(30, weight: .bold))
                .appTracking(5)
                .textCase(.uppercase)
                .foregroundStyle(isSuddenDeath ? AppColors.stateSkip : AppColors.accentAmber)
                .shadow(
                    color: (isSuddenDeath ? AppColors.stateSkip : AppColors.accentAmber).opacity(0.5),
                    radius: 22
                )
                .lineLimit(2)
                .minimumScaleFactor(0.6)

            Text(l10n.t(isSuddenDeath ? "teams.suddenDeath.body" : "teams.intermission.body"))
                .font(AppFont.accent(13, italic: true))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 8)
    }

    private var nextUp: some View {
        VStack(spacing: 7) {
            if !isSuddenDeath {
                Text(
                    l10n.t(
                        "teams.turnOf",
                        [
                            "current": "\(match.matchTurnNumber)",
                            "total": "\(match.matchTurnTotal)",
                        ]
                    )
                )
                .font(AppFont.ui(9, weight: .semibold))
                .appTracking(2.5)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textMuted)
            }

            HStack(spacing: 9) {
                Circle()
                    .fill(teamColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: teamColor.opacity(0.8), radius: 8)

                Text(match.teams[teamIndex].name)
                    .font(AppFont.display(21, weight: .bold))
                    .appTracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textCream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            // § `09` §5: oyuncu adı opsiyonel — girilmemişse takım adıyla yetiniliyor.
            Text(
                player.map { l10n.t("teams.handTo", ["name": $0]) }
                    ?? l10n.t("teams.handToTeam")
            )
            .font(AppFont.ui(11.5))
            .foregroundStyle(AppColors.textMuted)
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            VStack(spacing: 0) {
                Text("\(max(0, secondsLeft))")
                    .font(AppFont.display(46, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(AppColors.accentGold)
                Text(l10n.t("teams.seconds"))
                    .font(AppFont.ui(8.5, weight: .semibold))
                    .appTracking(3)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(.top, 4)
            .accessibilityLabel(l10n.t("teams.seconds.left", ["count": "\(max(0, secondsLeft))"]))
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 8)
    }
}

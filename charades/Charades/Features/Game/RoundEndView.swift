import SwiftUI


struct RoundEndView: View {
    let game: LiveGame
    var onPlayAgain: () -> Void

    var onNextTeam: () -> Void = {}
    var onExit: () -> Void

    var onWatchReplay: () -> Void = {}

    @Environment(LocalizationManager.self) private var l10n
    @State private var isConfirmingQuit = false

    private var match: TeamMatch? { game.match }

    var body: some View {
        VStack(spacing: 0) {
            header
            columns


            if game.mode == .ownWords, !game.customCards.isEmpty {
                SaveBasketBanner(words: game.customCards.map { $0.text(for: l10n.localeCode) })
                    .padding(.top, 10)
            }

            footer
        }
        .background {
            LinearGradient(
                colors: [AppColors.surfacePoster, AppColors.surfaceTicket],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay {
                HalftoneTexture(dotSize: 0.6, spacing: 3.5, color: .black.opacity(0.45))
                    .opacity(0.16)
            }
            .ignoresSafeArea()
        }


        .overlay { LetterboxBars() }

        .confirmationDialog(
            l10n.t("pause.exit.confirm.title.match"),
            isPresented: $isConfirmingQuit,
            titleVisibility: .visible
        ) {
            Button(l10n.t("pause.exit.confirm.action"), role: .destructive, action: onExit)
            Button(l10n.t("common.cancel"), role: .cancel) {}
        } message: {
            Text(l10n.t("pause.exit.confirm.body.match"))
        }
    }


    private var header: some View {
        VStack(spacing: 2) {
            if let match {
                teamCaption(match)
            } else {
                Text(l10n.t(game.mode.titleKey))
                    .font(AppFont.display(13, weight: .semibold))
                    .appTracking(4)
                    .textCase(.uppercase)
                    .foregroundStyle(Color(hex: 0x7A6A52))
            }

            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text("\(game.score)")
                    .font(AppFont.display(52, weight: .bold))
                    .foregroundStyle(AppColors.textOnPoster)
                Text(l10n.t("round.points"))
                    .font(AppFont.ui(11, weight: .semibold))
                    .appTracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(Color(hex: 0x7A6A52))
            }


            if game.isNewRapidRecord {
                Text(l10n.t("round.newRecord"))
                    .font(AppFont.display(11, weight: .bold))
                    .appTracking(3)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.surfacePoster)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background {
                        Capsule().fill(AppColors.accentAmberDeep)
                    }
                    .padding(.top, 4)
            }


            Text(l10n.t("round.fixHint"))
                .font(AppFont.ui(9))
                .appTracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textOnPosterMuted)
                .padding(.top, 5)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 16)
        .padding(.bottom, 10)
        .padding(.horizontal, 30)
    }


    private func teamCaption(_ match: TeamMatch) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 7) {
                Circle()
                    .fill(AppColors.team(match.currentTeamIndex))
                    .overlay {
                        Circle().strokeBorder(AppColors.textOnPoster.opacity(0.35), lineWidth: 1)
                    }
                    .frame(width: 10, height: 10)

                Text(match.currentTeam.name)
                    .font(AppFont.display(15, weight: .bold))
                    .appTracking(3)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textOnPoster)
            }

            Text(
                match.isSuddenDeath
                    ? l10n.t("teams.suddenDeath.title")
                    : l10n.t(
                        "teams.turnOf",
                        [
                            "current": "\(match.matchTurnNumber)",
                            "total": "\(match.matchTurnTotal)",
                        ]
                    )
            )
            .font(AppFont.ui(9, weight: .semibold))
            .appTracking(2)
            .textCase(.uppercase)
            .foregroundStyle(match.isSuddenDeath ? Color(hex: 0xA8382C) : Color(hex: 0x7A6A52))
        }
        .padding(.bottom, 2)
    }


    private var columns: some View {
        HStack(spacing: 0) {
            column(
                title: l10n.t("round.correct", ["count": "\(game.correctAnswers.count)"]),
                icon: "checkmark",
                tint: Color(hex: 0x3F7A4B),
                answers: game.correctAnswers
            )
            .overlay(alignment: .trailing) { perforation }

            column(
                title: l10n.t("round.skipped", ["count": "\(game.skippedAnswers.count)"]),
                icon: "xmark",
                tint: Color(hex: 0xA8382C),
                answers: game.skippedAnswers
            )
        }

        .padding(.leading, 62)
        .padding(.trailing, 30)
    }

    private var perforation: some View {
        Canvas { context, size in
            let dash: CGFloat = 4
            var y: CGFloat = 0
            while y < size.height {
                let rect = CGRect(x: (size.width - 1.5) / 2, y: y, width: 1.5, height: min(dash, size.height - y))
                context.fill(Path(rect), with: .color(AppColors.textOnPoster.opacity(0.28)))
                y += dash * 2
            }
        }
        .frame(width: 1.5)
        .allowsHitTesting(false)
    }

    private func column(
        title: String,
        icon: String,
        tint: Color,
        answers: [LiveGame.Answer]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(AppFont.ui(9.5, weight: .bold))
                    .appTracking(2)
                    .textCase(.uppercase)
            }
            .foregroundStyle(tint)
            .padding(.bottom, 7)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(answers) { answer in
                        Button {
                            game.toggleAnswer(answer.id)
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(tint)
                                    .frame(width: 5, height: 5)
                                Text(answer.card.text(for: l10n.localeCode))
                                    .font(AppFont.display(15, weight: .medium))
                                    .appTracking(0.7)
                                    .foregroundStyle(
                                        answer.isCorrect
                                            ? AppColors.textOnPoster
                                            : Color(hex: 0x5F5346)
                                    )
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 3.5)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .animation(.easeOut(duration: 0.2), value: game.answers)
    }


    private var footer: some View {
        HStack(spacing: 11) {
            if match == nil {
                TicketButton(
                    title: l10n.t("round.backToStage"),
                    systemImage: "chevron.left",
                    isPrimary: false,
                    action: onExit
                )
                replayButton
                TicketButton(
                    title: l10n.t("round.playAgain"),
                    systemImage: "play.fill",
                    isPrimary: true,
                    action: onPlayAgain
                )
            } else {
                TicketButton(
                    title: l10n.t("teams.quitMatch"),
                    systemImage: "xmark",
                    isPrimary: false
                ) {
                    isConfirmingQuit = true
                }
                replayButton
                TicketButton(
                    title: l10n.t(game.isFinalTeamTurn ? "teams.finishMatch" : "teams.nextTeam"),
                    systemImage: "play.fill",
                    isPrimary: true,
                    action: onNextTeam
                )
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .animation(.easeOut(duration: 0.2), value: game.reel != nil)
    }


    @ViewBuilder
    private var replayButton: some View {
        if game.reel != nil {
            TicketButton(
                title: l10n.t("round.watchReplay"),
                systemImage: "film",
                isPrimary: false,
                action: onWatchReplay
            )
        }
    }
}

private struct TicketButton: View {
    let title: String
    let systemImage: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button {
            if isPrimary { Haptics.primaryButton() } else { Haptics.secondaryButton() }
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(AppFont.display(13, weight: .semibold))
                    .appTracking(2)
                    .textCase(.uppercase)
            }
            .foregroundStyle(isPrimary ? AppColors.surfacePoster : AppColors.textOnPoster)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background {
                RoundedRectangle(cornerRadius: 11)
                    .fill(isPrimary ? AppColors.bgVelvetDeep : .clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 11).strokeBorder(
                            isPrimary ? AppColors.bgVelvetDeep : AppColors.textOnPoster.opacity(0.3),
                            lineWidth: 1.5
                        )
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

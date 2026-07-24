import SwiftUI
import Combine

struct DiscussionView: View {
    @Bindable var live: LiveGame
    var onVote: () -> Void

    @Bindable private var l10n = LocalizationManager.shared
    @State private var showHowTo = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button {
                        Haptics.light()
                        showHowTo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                Text(l10n.t("app.name"))
                    .font(AppFont.display(28, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(l10n.t("round.startAsking"))
                    .font(AppFont.ui(18, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)

                Text(timeString)
                    .font(AppFont.display(64, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .monospacedDigit()

                Spacer()

                if live.isPaused || live.remainingSeconds == 0 {
                    HStack(spacing: 12) {
                        Button {
                            Haptics.light()
                            live.isPaused = false
                            if live.remainingSeconds == 0 {
                                live.remainingSeconds = live.roundDurationSeconds
                            }
                        } label: {
                            Text(l10n.t("round.resume"))
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button {
                            onVote()
                        } label: {
                            Text(l10n.t("round.vote"))
                        }
                        .buttonStyle(SecondaryCapsuleButtonStyle())
                    }
                    .padding(.horizontal, 20)
                } else {
                    Button {
                        Haptics.light()
                        live.isPaused = true
                    } label: {
                        Text(l10n.t("round.pause"))
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 28)

            if live.isPaused && live.remainingSeconds > 0 {
                Color.black.opacity(0.35).ignoresSafeArea()
                VStack(spacing: 10) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                    Text(l10n.t("round.paused"))
                        .font(AppFont.display(28, weight: .bold))
                        .foregroundStyle(.white)
                    Text(l10n.t("round.tapToContinue"))
                        .font(AppFont.ui(15))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .onTapGesture {
                    Haptics.light()
                    live.isPaused = false
                }
            }
        }
        .onReceive(timer) { _ in
            live.tick()
        }
        .sheet(isPresented: $showHowTo) {
            HowToPlaySheet()
        }
    }

    private var timeString: String {
        let m = live.remainingSeconds / 60
        let s = live.remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct VotingView: View {
    @Bindable var live: LiveGame
    @Bindable private var l10n = LocalizationManager.shared
    @State private var selectedID: UUID?

    /// Single-device party: one collective vote selection, then send.
    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text(l10n.t("vote.title"))
                        .font(AppFont.display(28, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(selectedID == nil ? l10n.t("vote.instruction") : l10n.t("vote.ready"))
                        .font(AppFont.ui(15))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(live.players) { player in
                            voteCard(player)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 110)
                }

                Button {
                    guard let selectedID else { return }
                    // Record one vote per player toward selected (party phone consensus)
                    for p in live.players {
                        live.castVote(voter: p.id, target: selectedID)
                    }
                    live.submitVotes()
                } label: {
                    Text(l10n.t("vote.send"))
                        .font(AppFont.ui(17, weight: .bold))
                        .foregroundStyle(selectedID == nil ? AppColors.btnDisabledText : AppColors.textOnLight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 22,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 22
                            )
                            .fill(selectedID == nil ? AppColors.btnDisabledBg : AppColors.btnPrimaryBg)
                        )
                }
                .disabled(selectedID == nil)
            }
        }
    }

    private func voteCard(_ player: AssignedPlayer) -> some View {
        let selected = selectedID == player.id
        return Button {
            Haptics.medium()
            selectedID = player.id
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(player.avatarImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .background(player.accent)

                    if selected {
                        Text("1")
                            .font(AppFont.ui(12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(AppColors.stateDanger))
                            .padding(8)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text(player.name)
                    .font(AppFont.ui(16, weight: .bold))
                    .foregroundStyle(AppColors.textOnLight)
                    .padding(.bottom, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(selected ? AppColors.accentCyan : .clear, lineWidth: 3)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct ResultsView: View {
    @Bindable var live: LiveGame
    var onPlayAgain: () -> Void
    @Bindable private var l10n = LocalizationManager.shared

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 16) {
                Text(l10n.t("results.title"))
                    .font(AppFont.display(28, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.top, 16)

                VStack(spacing: 12) {
                    Text(titleText)
                        .font(AppFont.display(26, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitleText)
                        .font(AppFont.ui(15))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)

                    if showsImposterPortrait, let impostor = live.impostors.first {
                        playerSpotlight(impostor, caption: nil)
                    }

                    if case .decoy = live.activeTwist, let decoy = live.decoyPlayer {
                        playerSpotlight(decoy, caption: l10n.t("results.decoyPlayer"))
                    }

                    if case .blank = live.activeTwist, let blank = live.blankPlayer {
                        playerSpotlight(blank, caption: l10n.t("results.blankPlayer"))
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(AppColors.surfaceCard)
                )
                .padding(.horizontal, 16)

                VStack(spacing: 6) {
                    Text(l10n.t("results.secretWord"))
                        .font(AppFont.ui(13))
                        .foregroundStyle(AppColors.textSecondary)
                    Text(live.secretWord)
                        .font(AppFont.display(26, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    if let decoy = live.decoyWord {
                        Text(l10n.t("results.decoyWord", ["word": decoy]))
                            .font(AppFont.ui(13))
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.top, 4)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(AppColors.surfaceCard)
                )
                .padding(.horizontal, 16)

                Spacer()

                Button(action: onPlayAgain) {
                    HStack {
                        Text(l10n.t("results.playAgain"))
                        Image(systemName: "arrow.clockwise")
                    }
                    .font(AppFont.ui(17, weight: .bold))
                    .foregroundStyle(AppColors.textOnLight)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 22,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 22
                        )
                        .fill(AppColors.btnPrimaryBg)
                    )
                }
            }
        }
    }

    private var showsImposterPortrait: Bool {
        switch live.outcome {
        case .crewWins, .imposterWinsHidden: return true
        case .twistNoImposter, .twistAllImposters: return false
        case .none: return false
        }
    }

    private func playerSpotlight(_ player: AssignedPlayer, caption: String?) -> some View {
        VStack(spacing: 8) {
            if let caption {
                Text(caption)
                    .font(AppFont.ui(12, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }
            Image(player.avatarImageName)
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .background(player.accent)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Text(player.name)
                .font(AppFont.ui(18, weight: .bold))
                .foregroundStyle(AppColors.textOnLight)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
        )
        .padding(.top, 4)
    }

    private var titleText: String {
        switch live.outcome {
        case .crewWins: return l10n.t("results.crewWins")
        case .imposterWinsHidden: return l10n.t("results.imposterWins")
        case .twistNoImposter, .twistAllImposters: return l10n.t("results.twistTitle")
        case .none: return l10n.t("results.title")
        }
    }

    private var subtitleText: String {
        switch live.outcome {
        case .crewWins: return l10n.t("results.crewWinsBody")
        case .imposterWinsHidden: return l10n.t("results.imposterWinsBody")
        case .twistNoImposter: return l10n.t("results.twistNoImposterBody")
        case .twistAllImposters: return l10n.t("results.twistAllImpostersBody")
        case .none: return ""
        }
    }
}

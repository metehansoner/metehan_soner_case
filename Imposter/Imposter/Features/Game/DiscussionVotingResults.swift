import SwiftUI
import Combine

struct DiscussionView: View {
    @Bindable var live: LiveGame
    var onVote: () -> Void
    var onExit: () -> Void

    @Bindable private var l10n = LocalizationManager.shared
    @State private var showHowTo = false
    @State private var showExitConfirm = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 24) {
                HStack {
                    Button {
                        Haptics.light()
                        live.isPaused = true
                        showExitConfirm = true
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        Haptics.light()
                        showHowTo = true
                    } label: {
                        Image(systemName: "info.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                Text(l10n.t("app.name"))
                    .font(AppFont.display(28, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(l10n.t("round.startAsking"))
                    .font(AppFont.ui(18, weight: .bold))
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

            if live.isPaused && live.remainingSeconds > 0 && !showExitConfirm {
                ZStack {
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
                    .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    Haptics.light()
                    live.isPaused = false
                }
            }

            if showExitConfirm {
                ExitGameConfirmOverlay(
                    onCancel: {
                        showExitConfirm = false
                    },
                    onConfirm: {
                        showExitConfirm = false
                        onExit()
                    }
                )
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
                        .font(AppFont.display(28, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(selectedID == nil ? l10n.t("vote.instruction") : l10n.t("vote.ready"))
                        .font(AppFont.ui(15, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 14)

                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(live.players) { player in
                            voteCard(player)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }

            VStack {
                Spacer(minLength: 0)
                Button {
                    guard let selectedID else { return }
                    for p in live.players {
                        live.castVote(voter: p.id, target: selectedID)
                    }
                    live.submitVotes()
                } label: {
                    Text(l10n.t("vote.send"))
                }
                .buttonStyle(PrimaryButtonStyle(enabled: selectedID != nil))
                .disabled(selectedID == nil)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(
                    LinearGradient(
                        colors: [AppColors.bgPrimary.opacity(0), AppColors.bgPrimary.opacity(0.92)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
                )
            }
        }
    }

    private func voteCard(_ player: AssignedPlayer) -> some View {
        let selected = selectedID == player.id
        return Button {
            Haptics.medium()
            selectedID = player.id
        } label: {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    Image(player.avatarImageName)
                        .resizable()
                        .scaledToFit()
                        .padding(.top, 10)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity)
                        .frame(height: 118)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(player.accent)
                        )

                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(AppColors.textOnLight, AppColors.accentCyan)
                            .padding(8)
                    }
                }

                Text(player.name)
                    .font(AppFont.display(16, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppColors.surfaceCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        selected ? AppColors.accentCyan : AppColors.accentCyan.opacity(0.18),
                        lineWidth: selected ? 2.5 : 1
                    )
            )
            .animation(.easeOut(duration: 0.18), value: selected)
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

            VStack(spacing: 0) {
                Text(l10n.t("results.title"))
                    .font(AppFont.display(28, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.top, 16)
                    .padding(.bottom, 18)

                ScrollView {
                    VStack(spacing: 14) {
                        VStack(spacing: 14) {
                            Image(systemName: outcomeIcon)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(outcomeAccent)

                            Text(titleText)
                                .font(AppFont.display(26, weight: .black))
                                .foregroundStyle(AppColors.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(subtitleText)
                                .font(AppFont.ui(15, weight: .bold))
                                .foregroundStyle(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)

                            if showsImposterPortrait, let impostor = live.impostors.first {
                                playerSpotlight(impostor)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(AppColors.surfaceCard)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .strokeBorder(outcomeAccent.opacity(0.45), lineWidth: 1.5)
                        )

                        VStack(spacing: 8) {
                            Text(l10n.t("results.secretWord"))
                                .font(AppFont.ui(13, weight: .bold))
                                .foregroundStyle(AppColors.textSecondary)
                            Text(live.secretWord)
                                .font(AppFont.display(28, weight: .black))
                                .foregroundStyle(AppColors.accentCyan)
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(AppColors.surfaceCard)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .strokeBorder(AppColors.accentCyan.opacity(0.22), lineWidth: 1.5)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }

            VStack {
                Spacer(minLength: 0)
                Button(action: onPlayAgain) {
                    Text(l10n.t("results.playAgain"))
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(
                    LinearGradient(
                        colors: [AppColors.bgPrimary.opacity(0), AppColors.bgPrimary.opacity(0.92)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
                )
            }
        }
    }

    private var showsImposterPortrait: Bool {
        switch live.outcome {
        case .crewWins, .imposterWinsHidden: return true
        case .none: return false
        }
    }

    private var outcomeAccent: Color {
        switch live.outcome {
        case .crewWins: return AppColors.stateSuccess
        case .imposterWinsHidden: return AppColors.stateDanger
        case .none: return AppColors.accentCyan
        }
    }

    private var outcomeIcon: String {
        switch live.outcome {
        case .crewWins: return "checkmark.seal.fill"
        case .imposterWinsHidden: return "theatermasks.fill"
        case .none: return "sparkles"
        }
    }

    private func playerSpotlight(_ player: AssignedPlayer) -> some View {
        VStack(spacing: 10) {
            Image(player.avatarImageName)
                .resizable()
                .scaledToFit()
                .padding(.top, 8)
                .frame(height: 132)
                .frame(maxWidth: 160)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(player.accent)
                )

            Text(player.name)
                .font(AppFont.display(18, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.top, 6)
    }

    private var titleText: String {
        switch live.outcome {
        case .crewWins: return l10n.t("results.crewWins")
        case .imposterWinsHidden: return l10n.t("results.imposterWins")
        case .none: return l10n.t("results.title")
        }
    }

    private var subtitleText: String {
        switch live.outcome {
        case .crewWins: return l10n.t("results.crewWinsBody")
        case .imposterWinsHidden: return l10n.t("results.imposterWinsBody")
        case .none: return ""
        }
    }
}

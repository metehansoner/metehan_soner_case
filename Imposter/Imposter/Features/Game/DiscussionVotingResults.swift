import SwiftUI
import Combine

struct DiscussionView: View {
    @Bindable var live: LiveGame
    var onVote: () -> Void
    var onExit: () -> Void

    @Bindable private var l10n = LocalizationManager.shared
    @State private var showHowTo = false
    @State private var showExitConfirm = false
    @State private var promptIndex = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let promptKeys = [
        "round.prompt1", "round.prompt2", "round.prompt3",
        "round.prompt4", "round.prompt5"
    ]

    private var isEnded: Bool { live.remainingSeconds == 0 }
    private var isUrgent: Bool { live.remainingSeconds <= 10 && live.remainingSeconds > 0 }

    private var progress: CGFloat {
        guard live.roundDurationSeconds > 0 else { return 0 }
        return CGFloat(live.remainingSeconds) / CGFloat(live.roundDurationSeconds)
    }

    private var ringColor: Color {
        if isEnded { return AppColors.stateDanger }
        if isUrgent { return AppColors.stateDanger }
        return AppColors.accentCyan
    }

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                Spacer(minLength: 12)

                VStack(spacing: 20) {
                    Text(l10n.t(isEnded ? "round.timeUp" : promptKeys[promptIndex]))
                        .font(AppFont.display(24, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .frame(minHeight: 56, alignment: .center)
                        .id(isEnded ? -1 : promptIndex)
                        .transition(.opacity)

                    timerRing
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 12)

                controls
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }

            if showExitConfirm {
                ExitGameConfirmOverlay(
                    onCancel: {
                        showExitConfirm = false
                        live.isPaused = false
                    },
                    onConfirm: {
                        showExitConfirm = false
                        onExit()
                    }
                )
            } else if live.isPaused && !isEnded {
                PauseOverlay(
                    onResume: { live.isPaused = false },
                    onVote: {
                        live.isPaused = false
                        onVote()
                    }
                )
            }
        }
        .onReceive(timer) { _ in
            live.tick()
            if !live.isPaused, live.remainingSeconds > 0, live.remainingSeconds % 4 == 0 {
                withAnimation(.easeInOut(duration: 0.4)) {
                    promptIndex = (promptIndex + 1) % promptKeys.count
                }
            }
        }
        .sheet(isPresented: $showHowTo) {
            HowToPlaySheet(mode: live.mode)
        }
    }

    private var header: some View {
        ZStack {
            Text(l10n.t("round.discussTitle"))
                .font(AppFont.display(18, weight: .black))
                .foregroundStyle(AppColors.accentCyan)
                .textCase(.uppercase)

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
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 44)
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(AppColors.surfaceCardElevated.opacity(0.6), lineWidth: 12)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: ringColor.opacity(0.5), radius: 10)
                .animation(.linear(duration: 0.9), value: progress)

            VStack(spacing: 4) {
                Text(timeString)
                    .font(AppFont.display(52, weight: .black))
                    .foregroundStyle(isUrgent || isEnded ? AppColors.stateDanger : AppColors.textPrimary)
                    .monospacedDigit()
                    .scaleEffect(isUrgent ? 1.06 : 1)
                    .animation(.spring(response: 0.25, dampingFraction: 0.5), value: live.remainingSeconds)
                if live.isPaused && !isEnded {
                    Text(l10n.t("round.paused"))
                        .font(AppFont.ui(13, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .frame(width: 220, height: 220)
        .frame(maxHeight: 260)
    }

    @ViewBuilder
    private var controls: some View {
        HStack(spacing: 12) {
            if isEnded {
                Button {
                    Haptics.light()
                    live.isPaused = false
                    live.remainingSeconds = live.roundDurationSeconds
                } label: {
                    Text(l10n.t("round.restartTimer"))
                }
                .buttonStyle(SecondaryCapsuleButtonStyle())
            } else if live.isPaused {
                Button {
                    Haptics.light()
                    live.isPaused = false
                } label: {
                    Text(l10n.t("round.resume"))
                }
                .buttonStyle(SecondaryCapsuleButtonStyle())
            } else {
                Button {
                    Haptics.light()
                    live.isPaused = true
                } label: {
                    Text(l10n.t("round.pause"))
                }
                .buttonStyle(SecondaryCapsuleButtonStyle())
            }

            Button {
                Haptics.light()
                onVote()
            } label: {
                Text(l10n.t("round.vote"))
            }
            .buttonStyle(PrimaryButtonStyle())
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

    /// Single-device party: accuse one suspect, then reveal the truth.
    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text(l10n.t("vote.label"))
                        .font(AppFont.section(14))
                        .foregroundStyle(AppColors.stateDanger)
                        .textCase(.uppercase)
                    Text(l10n.t("vote.title"))
                        .font(AppFont.display(30, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(selectedID == nil ? l10n.t("vote.accuseHint") : l10n.t("vote.ready"))
                        .font(AppFont.ui(15, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
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
                    Haptics.heavy()
                    for p in live.players {
                        live.castVote(voter: p.id, target: selectedID)
                    }
                    live.submitVotes()
                } label: {
                    Text(l10n.t("vote.reveal"))
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
        let dimmed = selectedID != nil && !selected
        return Button {
            Haptics.medium()
            selectedID = player.id
        } label: {
            VStack(spacing: 10) {
                ZStack(alignment: .top) {
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
                        Text(l10n.t("vote.accused"))
                            .font(AppFont.section(11))
                            .foregroundStyle(.white)
                            .textCase(.uppercase)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(AppColors.stateDanger))
                            .offset(y: -6)
                            .transition(.scale.combined(with: .opacity))
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
                        selected ? AppColors.stateDanger : AppColors.accentCyan.opacity(0.18),
                        lineWidth: selected ? 2.5 : 1
                    )
            )
            .shadow(color: selected ? AppColors.stateDanger.opacity(0.5) : .clear, radius: 16)
            .scaleEffect(selected ? 1.03 : 1)
            .opacity(dimmed ? 0.5 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: selectedID)
        }
        .buttonStyle(.plain)
    }
}

struct ResultsView: View {
    @Bindable var live: LiveGame
    var onPlayAgain: () -> Void
    @Bindable private var l10n = LocalizationManager.shared
    @State private var appear = false

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                Text(l10n.t("results.momentOfTruth"))
                    .font(AppFont.section(14))
                    .foregroundStyle(outcomeAccent)
                    .textCase(.uppercase)
                    .padding(.top, 18)
                    .padding(.bottom, 12)

                ScrollView {
                    VStack(spacing: 14) {
                        VStack(spacing: 14) {
                            Image(systemName: outcomeIcon)
                                .font(.system(size: 44, weight: .bold))
                                .foregroundStyle(outcomeAccent)
                                .shadow(color: outcomeAccent.opacity(0.5), radius: 14)
                                .scaleEffect(appear ? 1 : 0.5)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appear)

                            Text(titleText)
                                .font(AppFont.display(30, weight: .black))
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
                        .padding(22)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(AppColors.surfaceCard)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(outcomeAccent.opacity(0.5), lineWidth: 1.5)
                        )
                        .shadow(color: outcomeAccent.opacity(0.25), radius: 22)

                        wordCard(
                            label: l10n.t("results.secretWord"),
                            word: live.secretWord,
                            accent: AppColors.accentCyan
                        )

                        if let decoy = live.decoyWord {
                            wordCard(
                                label: l10n.t("results.decoyWordLabel"),
                                word: decoy,
                                accent: AppColors.accentYellow
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 120)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 18)
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appear = true }
        }
    }

    private func wordCard(label: String, word: String, accent: Color) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(AppFont.ui(13, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
            Text(word)
                .font(AppFont.display(30, weight: .black))
                .foregroundStyle(accent)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.surfaceCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(accent.opacity(0.3), lineWidth: 1.5)
        )
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
            ZStack(alignment: .top) {
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

                Text(l10n.t("reveal.imposterTag"))
                    .font(AppFont.section(11))
                    .foregroundStyle(.white)
                    .textCase(.uppercase)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(AppColors.stateDanger))
                    .offset(y: -6)
            }

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

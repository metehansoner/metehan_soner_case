import SwiftUI


struct GameFlowView: View {
    let game: LiveGame
    var onHowToPlay: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppSettingsStore.self) private var settings
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.accessibilityReduceMotion) private var reduceMotion


    @State private var showsSoftPaywall = false
    @State private var showsFullPaywall = false


    @State private var showsReplay = false

    var body: some View {
        ZStack {
            phaseContent

            if showsSoftPaywall {
                SoftPaywallPanel(
                    onSeeTicket: {
                        showsSoftPaywall = false
                        showsFullPaywall = true
                    },
                    onClose: { showsSoftPaywall = false }
                )
            }

            VStack {
                replayNotice
                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.22), value: game.phase)


        .forcedLandscape(game.prefersLandscape)
        .animation(
            reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.34, dampingFraction: 0.85),
            value: showsSoftPaywall
        )
        .fullScreenCover(isPresented: $showsReplay) {
            if let reel = game.reel {
                ReplayPlayerView(
                    reel: reel,
                    onDelete: {
                        game.deleteReel()
                        showsReplay = false
                    },
                    onClose: { showsReplay = false }
                )
                .forcedLandscape()
                .environment(l10n)
                .localizedLayout()
            }
        }
        .fullScreenCover(isPresented: $showsFullPaywall) {
            PaywallView(context: .roundEnd, variant: .modal) { showsFullPaywall = false }

                .environment(LocalizationManager.shared)
                .environment(AppSettingsStore.shared)
                .environment(SubscriptionStore.shared)
                .localizedLayout()
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {

            OrientationLock.shared.lockPortrait()
            syncBrightness()
        }
        .onChange(of: game.phase) { _, newPhase in
            OrientationLock.shared.lockPortrait()
            syncBrightness()
            if newPhase == .roundEnd { offerSoftPaywall() }
        }
        .onDisappear { ScreenBrightness.restore() }
        #if DEBUG


        .onChange(of: game.reel != nil) { _, hasReel in
            guard hasReel, ProcessInfo.processInfo.arguments.contains("-AutoReplay") else { return }
            showsReplay = true
        }
        #endif


        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                game.handleSceneActive()
            } else {
                ScreenBrightness.restore()
                game.handleSceneInactive()
            }
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        ZStack {
            switch game.phase {
            case .slate:
                SlateView(
                    scene: game.sceneNumber,
                    take: game.takeNumber,
                    deckTitle: deckTitle,
                    modeTitle: l10n.t(game.mode.titleKey),
                    isFull: game.isSlateFull,
                    onFinish: game.finishSlate
                )


                .id("\(game.sceneNumber)-\(game.takeNumber)")
                .transition(.opacity)

            case .countdown:
                CountdownView(
                    value: game.countdownValue,
                    reel: game.sceneNumber,
                    onTap: game.shortenCountdown
                )
                    .transition(.opacity)

            case .playing:
                playing

            case .paused:
                ZStack {


                    GameCardView(game: game)
                    PauseOverlay(
                        reason: game.pauseReason,


                        cancelsMatch: game.match != nil,
                        onResume: game.resume,
                        onRestart: game.restartRound,
                        onHowToPlay: onHowToPlay,
                        onExit: game.exit
                    )
                }
                .transition(.opacity)

            case .roundEnd:
                RoundEndView(
                    game: game,
                    onPlayAgain: game.playAgain,
                    onNextTeam: game.finishTeamTurn,
                    onExit: game.exit,
                    onWatchReplay: { showsReplay = true }
                )
                .transition(.opacity)

            case .teamHandoff(let team, let player):
                if let match = game.match {
                    TeamTurnHandoffView(
                        match: match,
                        teamIndex: team,
                        player: player,
                        secondsLeft: game.handoffCountdown,
                        onReady: game.beginTeamTurn
                    )


                    .id(match.results.count)
                    .transition(.opacity)
                }

            case .matchEnd:
                if let match = game.match {
                    MatchEndView(
                        match: match,
                        hasReels: game.matchHasReels,
                        onRematch: game.rematch,
                        onArchive: game.openArchive,
                        onExit: game.exit
                    )
                        .transition(.opacity)
                }
            }
        }
    }


    @ViewBuilder
    private var replayNotice: some View {
        if let key = ReplayRecorder.shared.noticeKey {
            Text(l10n.t(key))
                .font(AppFont.ui(10, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textCream)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    Capsule()
                        .fill(AppColors.bgFilmBlack.opacity(0.92))
                        .overlay {
                            Capsule().strokeBorder(AppColors.accentGold.opacity(0.4), lineWidth: 1)
                        }
                }
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task {
                    try? await Task.sleep(for: .seconds(4))
                    ReplayRecorder.shared.clearNotice()
                }
        }
    }


    private var deckTitle: String {
        if game.deckIDs.count == 1, let deck = DeckCatalog.deck(game.deckIDs[0]) {
            return l10n.t(deck.titleKey)
        }
        if game.deckIDs.count > 1 { return l10n.t("mode.mix.title") }
        return l10n.t(game.mode.titleKey)
    }

    private var playing: some View {
        GameCardView(game: game)
            .pauseGesture(


                allowsTwoFingerTap: false,
                onGestureBegan: game.lockTriggersForPauseGesture,
                onPause: { game.pause(reason: .user) }
            )
            .transition(.opacity)
    }


    private func offerSoftPaywall() {
        guard settings.shouldShowSoftPaywall(isPremium: subscriptions.isPremium) else { return }
        settings.markSoftPaywallSeen()
        showsSoftPaywall = true
    }


    private func syncBrightness() {
        if game.phase == .playing, !game.mode.screenVisibleToGuesser {
            ScreenBrightness.dim()
        } else {
            ScreenBrightness.restore()
        }
    }
}

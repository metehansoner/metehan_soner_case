import SwiftUI

enum MainHub {
    case players
    case home
}

struct RootView: View {
    @Bindable var settings = AppSettingsStore.shared
    @Bindable private var store = SubscriptionStore.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: GameSession
    @State private var path = NavigationPath()
    @State private var liveGame: LiveGame?
    @State private var mainHub: MainHub
    @State private var showProfileEditor = false
    @State private var showSplash = true
    @State private var isStartingGame = false
    @State private var startGameError: String?
    @State private var rewardedPassForNextGame = false

    private var softNotificationPromptID: String {
        "\(settings.onboardingDone)-\(showSplash)-\(mainHub == .home)-\(liveGame == nil)"
    }

    init() {
        let session = GameSession()
        _session = State(initialValue: session)
        _mainHub = State(initialValue: session.hasSavedRoster ? .home : .players)
    }

    var body: some View {
        ZStack {
            Group {
                if !settings.onboardingDone {
                    OnboardingView {
                        settings.onboardingDone = true
                        session.resetPlayersForNewLaunch()
                        mainHub = .players
                        Haptics.medium()
                    }
                } else if let liveGame {
                    GameFlowView(
                        live: liveGame,
                        onExitToSetup: {
                            self.liveGame = nil
                            path = NavigationPath()
                            mainHub = .home
                            Haptics.medium()
                        },
                        onPlayAgain: {
                            returnToHomeAfterPlayAgain()
                        }
                    )
                } else {
                    switch mainHub {
                    case .players:
                        AddPlayersView(
                            session: session,
                            presentation: .launch,
                            onContinue: {
                                session.savePlayers()
                                Haptics.medium()
                                mainHub = .home
                            }
                        )
                    case .home:
                        homeStack
                    }
                }
            }
            .environment(LocalizationManager.shared)
            .preferredColorScheme(.dark)
            .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }

            if isStartingGame {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                    }
                    .zIndex(2)
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(1400))
            withAnimation(.easeOut(duration: 0.35)) {
                showSplash = false
            }
        }
        .task(id: softNotificationPromptID) {
            await maybeAskNotificationPermission()
        }
        .onChange(of: scenePhase) { oldPhase, phase in
            guard phase == .active else { return }
            let fromBackground = oldPhase == .background || oldPhase == .inactive
            Task {
                await NotificationService.syncPreferenceWithSystem(
                    isReturningToForeground: fromBackground
                )
            }
        }
        .alert(
            LocalizationManager.shared.t("paywall.adFailed"),
            isPresented: Binding(
                get: { startGameError != nil },
                set: { if !$0 { startGameError = nil } }
            )
        ) {
            Button(LocalizationManager.shared.t("common.gotIt"), role: .cancel) {
                startGameError = nil
            }
        } message: {
            Text(startGameError ?? "")
        }
    }

    private var homeStack: some View {
        NavigationStack(path: $path) {
            HomeView(
                session: session,
                showsCloseButton: false,
                showsProfileButton: true,
                onProfile: {
                    Haptics.light()
                    showProfileEditor = true
                },
                onModeSelected: {
                    Haptics.medium()
                    path.append(AppRoute.categories)
                }
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .categories:
                    CategoriesView(
                        session: session,
                        onBack: { path.removeLast() },
                        onPlay: { path.append(AppRoute.gameSettings) }
                    )
                case .gameSettings:
                    GameSettingsView(
                        session: session,
                        onBack: { path.removeLast() },
                        onPlay: { startGameFromSettings() }
                    )
                case .home:
                    EmptyView()
                }
            }
        }
        .fullScreenCover(isPresented: $showProfileEditor) {
            AddPlayersView(
                session: session,
                presentation: .profile,
                onContinue: {
                    session.savePlayers()
                    Haptics.medium()
                    showProfileEditor = false
                },
                onClose: {
                    Haptics.light()
                    showProfileEditor = false
                }
            )
        }
    }

    private func goHome() {
        liveGame = nil
        path = NavigationPath()
        mainHub = .home
        isStartingGame = false
        Haptics.medium()
    }

    private func returnToHomeAfterPlayAgain() {
        startGameError = nil
        Haptics.medium()

        guard store.shouldRequireRewardedForNewGame else {
            goHome()
            return
        }

        isStartingGame = true
        RewardedAdService.shared.show(
            onRewarded: {
                rewardedPassForNextGame = true
                goHome()
            },
            onFailed: { message in
                isStartingGame = false
                startGameError = message
                Haptics.error()
                RewardedAdService.shared.preload()
            }
        )
    }

    private func startGameFromSettings() {
        startGameError = nil
        Haptics.medium()

        let begin = {
            rewardedPassForNextGame = false
            liveGame = LiveGame(from: session)
            path = NavigationPath()
            isStartingGame = false
        }

        if store.shouldRequireRewardedForNewGame, !rewardedPassForNextGame {
            isStartingGame = true
            RewardedAdService.shared.show(
                onRewarded: {
                    begin()
                },
                onFailed: { message in
                    isStartingGame = false
                    startGameError = message
                    Haptics.error()
                    RewardedAdService.shared.preload()
                }
            )
            return
        }

        begin()
    }

    private func maybeAskNotificationPermission() async {
        guard settings.onboardingDone else { return }
        guard !showSplash else { return }
        guard liveGame == nil else { return }
        guard mainHub == .home else { return }
        guard !settings.notificationPermissionPrompted else {
            if settings.notificationsEnabled {
                await NotificationService.refreshSchedule()
            }
            return
        }

        try? await Task.sleep(for: .seconds(7))
        guard !Task.isCancelled else { return }
        guard settings.onboardingDone, !showSplash, liveGame == nil, mainHub == .home else { return }
        guard !settings.notificationPermissionPrompted else { return }
        guard await NotificationService.authorizationStatus() == .notDetermined else {
            settings.notificationPermissionPrompted = true
            if await NotificationService.isAuthorized(), settings.notificationsEnabled {
                await NotificationService.refreshSchedule()
            }
            return
        }

        _ = await NotificationService.requestAuthorization()
    }
}

enum AppRoute: Hashable {
    case categories
    case gameSettings
    case home
}

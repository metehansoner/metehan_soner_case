import SwiftUI

enum MainHub {
    case players
    case home
}

struct RootView: View {
    @Bindable var settings = AppSettingsStore.shared
    @Bindable private var store = SubscriptionStore.shared
    @State private var session = GameSession()
    @State private var path = NavigationPath()
    @State private var liveGame: LiveGame?
    @State private var mainHub: MainHub = .players
    @State private var showProfileEditor = false
    /// Keeps the post-onboarding paywall on screen for this launch even after we persist `paywallSeen`.
    @State private var showLaunchPaywall = false

    var body: some View {
        Group {
            if !settings.onboardingDone {
                OnboardingView {
                    settings.onboardingDone = true
                    session.resetPlayersForNewLaunch()
                    mainHub = .players
                    if !store.isPremium {
                        showLaunchPaywall = true
                    }
                    Haptics.medium()
                }
            } else if showLaunchPaywall {
                PaywallView(presentation: .afterOnboarding) {
                    showLaunchPaywall = false
                    store.paywallSeen = true
                }
                .onAppear {
                    // Persist immediately so force-quit won't show launch paywall again.
                    store.paywallSeen = true
                }
            } else if let liveGame {
                GameFlowView(live: liveGame) {
                    self.liveGame = nil
                    path = NavigationPath()
                    // Keep player names for this session; return to mode hub.
                    mainHub = .home
                    Haptics.medium()
                }
            } else {
                switch mainHub {
                case .players:
                    AddPlayersView(
                        session: session,
                        presentation: .launch,
                        onContinue: {
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
        .onAppear {
            // Cold start: show launch paywall once if onboarding is done and it was never shown.
            if settings.onboardingDone, !store.paywallSeen, !store.isPremium {
                showLaunchPaywall = true
            }
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
                        onPlay: { startLiveGame() }
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

    private func startLiveGame() {
        Haptics.medium()
        liveGame = LiveGame(from: session)
    }
}

enum AppRoute: Hashable {
    case categories
    case gameSettings
    case home
}

import SwiftUI

struct RootView: View {
    @Bindable var settings = AppSettingsStore.shared
    @Bindable private var store = SubscriptionStore.shared
    @State private var session = GameSession()
    @State private var path = NavigationPath()
    @State private var showHome = false
    @State private var liveGame: LiveGame?

    var body: some View {
        Group {
            if !settings.onboardingDone {
                OnboardingView {
                    settings.onboardingDone = true
                    session.resetPlayersForNewLaunch()
                    Haptics.medium()
                }
            } else if shouldShowPaywall {
                PaywallView {
                    store.paywallSeen = true
                }
            } else if let liveGame {
                GameFlowView(live: liveGame) {
                    self.liveGame = nil
                    path = NavigationPath()
                    session.resetPlayersForNewLaunch()
                    Haptics.medium()
                }
            } else {
                mainStack
            }
        }
        .environment(LocalizationManager.shared)
        .preferredColorScheme(.dark)
        .onAppear {
            if settings.onboardingDone, liveGame == nil, !shouldShowPaywall {
                session.resetPlayersForNewLaunch()
            }
        }
    }

    private var shouldShowPaywall: Bool {
        !store.paywallSeen && !store.isPremium
    }

    private var mainStack: some View {
        NavigationStack(path: $path) {
            AddPlayersView(
                session: session,
                onOpenHome: {
                    Haptics.light()
                    showHome = true
                },
                onContinue: {
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
                    HomeView(session: session)
                }
            }
        }
        .sheet(isPresented: $showHome) {
            NavigationStack {
                HomeView(session: session)
            }
            .presentationDetents([.large])
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

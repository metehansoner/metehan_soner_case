import SwiftUI

struct GameFlowView: View {
    @Bindable var live: LiveGame
    var onExitToSetup: () -> Void
    var onPlayAgain: () -> Void

    @Bindable private var store = SubscriptionStore.shared
    @State private var showRateUs = false
    @State private var showSoftPaywall = false
    @State private var didMarkCompletion = false
    @State private var pendingRatePrompt = false

    var body: some View {
        Group {
            switch live.phase {
            case .passPhone(let index), .reveal(let index):
                if let player = live.player(at: index) {
                    let showHint: String? = {
                        guard live.hintsEnabled, case .impostor = player.reveal else { return nil }
                        return live.hint
                    }()
                    let isLast = index == live.players.count - 1
                    let nextName = isLast ? nil : live.player(at: index + 1)?.name
                    RoleRevealView(
                        player: player,
                        hint: showHint,
                        isLastPlayer: isLast,
                        nextPlayerName: nextName
                    ) {
                        live.advanceAfterReveal()
                    }
                    .id(player.id)
                }
            case .ready:
                ReadyToStartView {
                    live.startRound()
                }
            case .clueRound(let pos):
                if let player = live.cluePlayer(atPosition: pos) {
                    ClueRoundView(
                        live: live,
                        player: player,
                        position: pos,
                        onNext: { live.advanceClue() },
                        onExit: onExitToSetup
                    )
                    .id(pos)
                }
            case .discussion:
                DiscussionView(
                    live: live,
                    onVote: {
                        live.phase = .voting
                        Haptics.medium()
                    },
                    onExit: onExitToSetup
                )
            case .drawing:
                DrawingRoundView(
                    live: live,
                    onVote: {
                        live.phase = .voting
                        Haptics.medium()
                    },
                    onExit: onExitToSetup
                )
            case .voting:
                VotingView(live: live)
            case .results:
                ResultsView(live: live, onPlayAgain: onPlayAgain)
                    .onAppear(perform: handleResultsAppear)
            }
        }
        .sheet(isPresented: $showRateUs) {
            RateUsSheet {
                showRateUs = false
            }
        }
        .fullScreenCover(isPresented: $showSoftPaywall) {
            PaywallView(presentation: .afterOnboarding) {
                store.paywallSeen = true
                showSoftPaywall = false
                if pendingRatePrompt {
                    pendingRatePrompt = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showRateUs = true
                    }
                }
            }
            .onAppear {
                store.paywallSeen = true
            }
        }
    }

    private func handleResultsAppear() {
        guard !didMarkCompletion else { return }
        didMarkCompletion = true
        store.markGameCompleted()

        let wantsRate = store.shouldAskForRating
        if store.shouldOfferSoftPaywall {
            pendingRatePrompt = wantsRate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                showSoftPaywall = true
            }
        } else if wantsRate {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showRateUs = true
            }
        }
    }
}

import SwiftUI

struct GameFlowView: View {
    @Bindable var live: LiveGame
    var onExitToSetup: () -> Void

    @State private var showRateUs = false
    @State private var didMarkCompletion = false

    var body: some View {
        Group {
            switch live.phase {
            case .passPhone(let index):
                if let player = live.player(at: index) {
                    PassPhoneView(player: player) {
                        live.phase = .reveal(index)
                        Haptics.light()
                    }
                }
            case .reveal(let index):
                if let player = live.player(at: index) {
                    let showHint: String? = {
                        guard live.hintsEnabled, case .impostor = player.reveal else { return nil }
                        return live.hint
                    }()
                    RoleRevealView(player: player, hint: showHint) {
                        live.advanceAfterReveal()
                    }
                }
            case .ready:
                ReadyToStartView(mysteryTwistEnabled: live.mysteryTwistEnabled) {
                    live.startRound()
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
                ResultsView(live: live, onPlayAgain: onExitToSetup)
                    .onAppear {
                        guard !didMarkCompletion else { return }
                        didMarkCompletion = true
                        SubscriptionStore.shared.markGameCompleted()
                        if SubscriptionStore.shared.shouldAskForRating {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                showRateUs = true
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showRateUs) {
            RateUsSheet {
                showRateUs = false
            }
        }
    }
}

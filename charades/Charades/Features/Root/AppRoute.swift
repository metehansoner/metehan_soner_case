import Observation
import SwiftUI


enum AppRoute: Hashable {
    case mix
    case customList
    case customEditor(String?)
    case wordBasket


    case teamSetup(resumesModeSelect: Bool)
    case archive
    case archivePlayer(String)
}


enum PaywallContext: Hashable, Identifiable {
    case vipButton
    case lockedDeck(String)
    case lockedMode(String)
    case mix

    case customDeck

    case roundEnd

    var id: String {
        switch self {
        case .vipButton: "vipButton"
        case .lockedDeck(let id): "lockedDeck.\(id)"
        case .lockedMode(let id): "lockedMode.\(id)"
        case .mix: "mix"
        case .customDeck: "customDeck"
        case .roundEnd: "roundEnd"
        }
    }


    var isInvoluntary: Bool {
        switch self {
        case .vipButton, .roundEnd: false
        default: true
        }
    }
}


enum PaywallVariant {

    case onboarding

    case modal


    var analyticsName: String {
        switch self {
        case .onboarding: "onboarding"
        case .modal: "modal"
        }
    }
}


enum SetupStep: Hashable {

    case mode


    case howToPlay(mode: GameMode, continuesToGame: Bool)
}


@MainActor
@Observable
final class AppRouter {
    var path: [AppRoute] = []


    var deckDetailID: String?
    var isShowingSettings = false

    var setupStep: SetupStep?
    var paywall: PaywallContext?


    private(set) var paywallVariant: PaywallVariant = .modal


    static let maxInvoluntaryPaywallsPerSession = 3
    private var involuntaryPaywallCount = 0

    var lockedNotice: String?


    private var pendingSetupStep: SetupStep?

    func push(_ route: AppRoute) { path.append(route) }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() { path.removeAll() }

    func openDeckDetail(_ deckID: String) {
        Analytics.deckOpen(deckID: deckID)
        deckDetailID = deckID
    }

    func openPaywall(_ context: PaywallContext, variant: PaywallVariant = .onboarding) {


        if case .lockedDeck(let deckID) = context {
            Analytics.deckLockedTap(deckID: deckID)
        }

        if context.isInvoluntary {
            guard involuntaryPaywallCount < Self.maxInvoluntaryPaywallsPerSession else {
                lockedNotice = LocalizationManager.shared.t("paywall.notice.locked")
                return
            }
            involuntaryPaywallCount += 1
        }


        paywallVariant = .onboarding
        _ = variant
        deckDetailID = nil
        setupStep = nil
        paywall = context
    }


    func beginSetup() { setupStep = .mode }

    func closeSetup() { setupStep = nil }


    func beginSetupAfterDeckDetail() { closeDeckDetail(opening: .mode) }

    func openHowToPlayAfterDeckDetail(for mode: GameMode) {
        closeDeckDetail(opening: .howToPlay(mode: mode, continuesToGame: false))
    }

    func deckDetailDismissed() {
        guard let step = pendingSetupStep else { return }
        pendingSetupStep = nil
        setupStep = step
    }


    func openHowToPlay(for mode: GameMode) {
        setupStep = .howToPlay(mode: mode, continuesToGame: false)
    }

    private func closeDeckDetail(opening step: SetupStep) {
        pendingSetupStep = step
        deckDetailID = nil
    }
}

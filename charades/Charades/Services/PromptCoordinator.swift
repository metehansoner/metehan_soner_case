import Observation


@MainActor
@Observable
final class PromptCoordinator {
    static let shared = PromptCoordinator()

    enum Prompt {
        case softPaywall
        case notifications
        case rateUs
    }


    private(set) var shown: Prompt?

    private init() {}


    func claim(_ prompt: Prompt) -> Bool {
        guard shown == nil else { return false }
        shown = prompt
        return true
    }

    #if DEBUG
    func debugReset() { shown = nil }
    #endif
}

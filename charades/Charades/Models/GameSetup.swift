import Foundation
import Observation


@MainActor
@Observable
final class GameSetup {


    private(set) var selectedDeckIDs: [String] = [] {


        didSet { if !selectedDeckIDs.isEmpty { customDeckID = nil } }
    }

    var mode: GameMode = .classic {


        didSet { if mode != oldValue { duration = nil } }
    }


    var duration: Int?
    var difficulty: CardDifficultyFilter?


    var basketWords: [String] = AppSettingsStore.shared.basketDraft {
        didSet { AppSettingsStore.shared.storeBasketDraft(basketWords) }
    }


    var customDeckID: UUID?


    var teams: [Team] = Team.defaultRoster


    var roundsPerTeam = Team.defaultRounds


    func matchTeams(numbered: (Int) -> String) -> [Team] {
        teams.enumerated().map { $1.resolvingName(order: $0, numbered: numbered) }
    }


    func tidyTeams() {
        for index in teams.indices {
            teams[index].players = teams[index].namedPlayers
            teams[index].name = teams[index].name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    func addTeam() {
        guard teams.count < Team.countRange.upperBound else { return }
        teams.append(Team())
    }

    func removeTeam(_ id: UUID) {
        guard teams.count > Team.countRange.lowerBound else { return }
        teams.removeAll { $0.id == id }
    }


    func effectiveDuration(userPreference: Int) -> Int {
        guard !mode.isDurationLocked else { return mode.defaultDuration }
        return duration ?? (mode.usesOwnDuration ? mode.defaultDuration : userPreference)
    }

    var hasSelection: Bool { !selectedDeckIDs.isEmpty }


    var isMix: Bool { selectedDeckIDs.count >= 2 }

    var selectedDecks: [DeckDef] { selectedDeckIDs.compactMap(DeckCatalog.deck) }


    var selectedCardCount: Int {
        selectedDeckIDs.reduce(0) { $0 + (DeckCardCounts.count(for: $1) ?? 0) }
    }

    func isSelected(_ deckID: String) -> Bool { selectedDeckIDs.contains(deckID) }

    func toggle(_ deckID: String) {
        if let index = selectedDeckIDs.firstIndex(of: deckID) {
            selectedDeckIDs.remove(at: index)
        } else {
            selectedDeckIDs.append(deckID)
        }
    }

    func select(only deckID: String) {
        selectedDeckIDs = [deckID]
    }


    func select(all deckIDs: [String]) {
        selectedDeckIDs = Array(deckIDs.prefix(MixLimits.deckRange.upperBound))
    }


    func mixOrder(of deckID: String) -> Int? {
        selectedDeckIDs.firstIndex(of: deckID).map { $0 + 1 }
    }


    func canToggleInMix(_ deckID: String) -> Bool {
        isSelected(deckID) || selectedDeckIDs.count < MixLimits.deckRange.upperBound
    }


    var isMixReady: Bool {
        MixLimits.deckRange.contains(selectedDeckIDs.count)
    }

    func clearSelection() {
        selectedDeckIDs.removeAll()
        customDeckID = nil
    }


    func select(custom deckID: UUID) {
        selectedDeckIDs.removeAll()
        customDeckID = deckID
    }


    var isBasketPlayable: Bool {
        basketWords.count >= CustomDeckLimits.minWordsToPlay
    }

    func basketCards(language: String) -> [Card] {
        basketWords.enumerated().map {
            Card.custom(key: "basket.\($0)", text: $1, language: language)
        }
    }


    func clearBasket() {
        basketWords.removeAll()
        AppSettingsStore.shared.clearBasketDraft()
    }
}

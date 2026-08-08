import Foundation
import SwiftData


enum MixLimits: Sendable {


    nonisolated static let deckRange = 2...8

    nonisolated static let maxSaved = 5
    nonisolated static let maxNameLength = 24
}


@Model
final class SavedMix {
    var uuid: UUID = UUID()
    var name: String = ""

    var deckIDs: [String] = []
    var createdAt: Date = Date.now

    var sortIndex: Int = 0

    init(name: String, deckIDs: [String], sortIndex: Int = 0) {
        uuid = UUID()
        self.name = String(name.prefix(MixLimits.maxNameLength))
        self.deckIDs = Array(deckIDs.prefix(MixLimits.deckRange.upperBound))
        self.sortIndex = sortIndex
        createdAt = .now
    }


    @MainActor
    var decks: [DeckDef] { deckIDs.compactMap(DeckCatalog.deck) }

    @MainActor
    var cardCount: Int {
        deckIDs.reduce(0) { $0 + (DeckCardCounts.count(for: $1) ?? 0) }
    }


    @MainActor
    var isPlayable: Bool {
        decks.count >= MixLimits.deckRange.lowerBound
    }
}

import Foundation
import SwiftData


enum CustomDeckLimits: Sendable {
    nonisolated static let maxNameLength = 24
    nonisolated static let maxWords = 100

    nonisolated static let minWordsToPlay = 5

    nonisolated static let recommendedWordCount = 20


    nonisolated static func maxDeckCount(isPremium: Bool) -> Int { isPremium ? 3 : 1 }
}


enum CustomDeckCover: Int, CaseIterable, Identifiable, Sendable {
    case animals = 0
    case people
    case vehicles
    case food
    case sports
    case music
    case travel
    case home
    case nature
    case party
    case jobs
    case fantasy

    nonisolated var id: Int { rawValue }
    nonisolated var titleKey: String { "customDeck.cover.\(String(describing: self))" }


    nonisolated static func deterministic(for name: String) -> CustomDeckCover {
        let all = allCases
        return all[Int(name.stableHash % UInt64(all.count))]
    }
}

private extension String {


    nonisolated var stableHash: UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }
}


@Model
final class CustomDeck {
    var uuid: UUID = UUID()
    var name: String = ""

    var coverTemplate: Int = 0


    var coverImageData: Data?


    var languageCode: String = "en"
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var sortIndex: Int = 0

    var savedFromBasket: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \CustomCard.deck)
    var cards: [CustomCard]? = []

    init(
        name: String,
        languageCode: String,
        cover: CustomDeckCover? = nil,
        savedFromBasket: Bool = false,
        sortIndex: Int = 0
    ) {
        uuid = UUID()
        self.name = String(name.prefix(CustomDeckLimits.maxNameLength))
        self.languageCode = languageCode
        coverTemplate = (cover ?? .deterministic(for: name)).rawValue
        self.savedFromBasket = savedFromBasket
        self.sortIndex = sortIndex
        createdAt = .now
        updatedAt = .now


        cards = []
    }

    var cover: CustomDeckCover {
        CustomDeckCover(rawValue: coverTemplate) ?? .animals
    }

    var orderedCards: [CustomCard] {
        (cards ?? []).sorted { $0.order < $1.order }
    }

    var wordCount: Int { cards?.count ?? 0 }

    var canPlay: Bool { wordCount >= CustomDeckLimits.minWordsToPlay }


    var hasListableContent: Bool {
        wordCount > 0
            || !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }


    var isBelowRecommended: Bool { wordCount < CustomDeckLimits.recommendedWordCount }


    func toCards() -> [Card] {
        orderedCards.map {
            Card.custom(
                key: "custom.\(uuid.uuidString).\($0.order)",
                text: $0.text,
                language: languageCode
            )
        }
    }

    var words: [String] { orderedCards.map(\.text) }


    func replaceWords(_ words: [String]) {
        var survivors = orderedCards
        while survivors.count > words.count {
            let removed = survivors.removeLast()
            modelContext?.delete(removed)
        }
        for (index, text) in words.prefix(CustomDeckLimits.maxWords).enumerated() {
            if index < survivors.count {
                survivors[index].text = text
                survivors[index].order = index
            } else {
                let card = CustomCard(text: text, order: index)
                card.deck = self
                modelContext?.insert(card)
                survivors.append(card)
            }
        }
        cards = survivors
        updatedAt = .now
    }
}

@Model
final class CustomCard {
    var text: String = ""
    var order: Int = 0
    var deck: CustomDeck?

    init(text: String, order: Int) {
        self.text = text
        self.order = order
    }
}


enum CustomDeckStore {
    static let schema = Schema([CustomDeck.self, CustomCard.self, SavedMix.self])


    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {


            assertionFailure("SwiftData container açılamadı: \(error)")
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: fallback)
        }
    }
}

extension ModelContext {


    @discardableResult
    func persistCustomDecks() -> Bool {
        do {
            try save()
            return true
        } catch {
            assertionFailure("SwiftData save failed: \(error)")
            return false
        }
    }
}

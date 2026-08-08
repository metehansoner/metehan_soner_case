import Foundation


struct DeckFile: Codable, Sendable {
    let id: String
    let version: Int
    let localize: LocalizationStyle
    let cards: [Card]
}


enum CardDifficultyFilter: String, CaseIterable, Sendable {
    case all
    case easy
    case hard

    var titleKey: String { "difficulty.filter.\(rawValue)" }

    func accepts(_ card: Card) -> Bool {
        guard card.d > 0 else { return true }
        switch self {
        case .all: return true
        case .easy: return card.d <= 2
        case .hard: return card.d >= 2
        }
    }
}


@MainActor
final class CardBank {
    static let shared = CardBank()


    private let cache: NSCache<NSString, CachedDeck> = {
        let cache = NSCache<NSString, CachedDeck>()
        cache.countLimit = 5
        return cache
    }()


    private var missingIDs: Set<String> = []

    private init() {}


    func hasContent(_ deckID: String) -> Bool {
        deckFile(deckID) != nil
    }

    func deckFile(_ deckID: String) -> DeckFile? {
        if let cached = cache.object(forKey: deckID as NSString) { return cached.file }
        if missingIDs.contains(deckID) { return nil }

        guard let file = Self.load(deckID) else {
            missingIDs.insert(deckID)
            return nil
        }
        cache.setObject(CachedDeck(file: file), forKey: deckID as NSString)
        return file
    }

    func cards(
        in deckID: String,
        difficulty: CardDifficultyFilter = .all
    ) -> [Card] {
        guard let file = deckFile(deckID) else { return [] }
        return difficulty == .all ? file.cards : file.cards.filter(difficulty.accepts)
    }


    func cardsByDeck(
        in deckIDs: [String],
        difficulty: CardDifficultyFilter = .all
    ) -> [[Card]] {
        deckIDs.map { cards(in: $0, difficulty: difficulty) }.filter { !$0.isEmpty }
    }

    func evictAll() {
        cache.removeAllObjects()
        missingIDs.removeAll()
    }

    private static func load(_ deckID: String) -> DeckFile? {
        let url =
            Bundle.main.url(forResource: deckID, withExtension: "json", subdirectory: "Resources/Decks")
            ?? Bundle.main.url(forResource: deckID, withExtension: "json", subdirectory: "Decks")
            ?? Bundle.main.url(forResource: deckID, withExtension: "json")
        guard let url, let data = try? Data(contentsOf: url) else { return nil }

        do {
            let file = try JSONDecoder().decode(DeckFile.self, from: data)


            guard file.id == deckID else {
                assertionFailure("Deste dosyası uyuşmuyor: \(deckID).json içinde id = \(file.id)")
                return nil
            }
            return file
        } catch {
            assertionFailure("Deste dosyası okunamadı: \(deckID).json — \(error)")
            return nil
        }
    }


    private final class CachedDeck {
        let file: DeckFile
        init(file: DeckFile) { self.file = file }
    }
}

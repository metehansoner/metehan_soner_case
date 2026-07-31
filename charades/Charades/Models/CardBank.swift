import Foundation

// MARK: - Kelime havuzu şeması

/// `Resources/Decks/{id}.json` dosyasının şeması.
struct DeckFile: Codable, Sendable {
    let id: String
    let version: Int
    let localize: LocalizationStyle
    let cards: [Card]
}

/// §06 §4: ayarlardaki `HEPSİ` / `KOLAY` / `ZOR` segmenti. Kartın `d` alanına
/// bakıyor; `d == 0` (custom) her zaman geçiyor. Orta zorluk (`2`) iki uçta da
/// sayılıyor — aksi hâlde filtrelenmiş havuz §09 §4'ün uyardığı boyuta düşüyor.
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

// MARK: - CardBank

/// §05 §5: deste seçildiğinde lazy yüklenir, son 5 deste bellekte tutulur.
/// Ana ekranda hiçbir kelime dosyası okunmaz.
@MainActor
final class CardBank {
    static let shared = CardBank()

    /// §05 §5: `NSCache` ile son 5 deste. Bellek baskısında sistem kendi boşaltıyor.
    private let cache: NSCache<NSString, CachedDeck> = {
        let cache = NSCache<NSString, CachedDeck>()
        cache.countLimit = 5
        return cache
    }()

    /// Bulunamayan dosyayı her çağrıda tekrar aramamak için.
    private var missingIDs: Set<String> = []

    private init() {}

    /// Deste dosyası bundle'da var mı — katalogda tanımlı ama içeriği henüz
    /// üretilmemiş desteler için (§10 §4, içerik ayrı bir yol).
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

    /// §05 §6: Mix'te desteler ayrı kuyruklar hâlinde kalıyor, birleştirilmiyor.
    /// Seçim sırası korunuyor; içeriği olmayan deste listeden düşüyor.
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
            // Dosya adı ile içindeki id ayrışırsa yanlış destenin kelimeleri
            // sessizce gelir — `Imposter`'da `hollywood` kategorisinde tam olarak
            // bu olmuş (§05 §5). Doğrulama script'i CI'da yakalıyor, burada da
            // çalışma zamanında reddediyoruz.
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

    /// `NSCache` referans tip istiyor.
    private final class CachedDeck {
        let file: DeckFile
        init(file: DeckFile) { self.file = file }
    }
}
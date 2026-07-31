import Foundation

// MARK: - Kelime havuzu şeması

/// §05 §5: tek kart. `Imposter`'daki tek `words.json` (590 KB) yerine deste
/// başına ayrı dosya — 12.000 kart × 25 dil tek dosyada ~15 MB eder ve
/// açılışta tamamı parse edilirdi.
struct Card: Codable, Hashable, Identifiable, Sendable {
    /// Dilden bağımsız kalıcı anahtar; tekrar kontrolü ve analytics bunu kullanıyor.
    let k: String
    /// 25 dilin karşılığı. `adapt` destelerde aynı `k` farklı dilde farklı
    /// kişi/şey olabilir (§06 §3.2) — bu yüzden "çeviri" değil karşılık.
    let t: [String: String]
    /// Zorluk 1–3. `0` nötr demek: custom kartların zorluğu yok ve zorluk
    /// filtresinden muaf tutuluyorlar (§09 §4).
    let d: Int

    nonisolated var id: String { k }

    nonisolated init(k: String, t: [String: String], d: Int = 0) {
        self.k = k
        self.t = t
        self.d = d
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        k = try container.decode(String.self, forKey: .k)
        t = try container.decode([String: String].self, forKey: .t)
        d = try container.decodeIfPresent(Int.self, forKey: .d) ?? 0
    }

    /// Eksik çeviri ham anahtar olarak görünmesin: dil → İngilizce → anahtar.
    nonisolated func text(for language: String) -> String {
        t[language] ?? t["en"] ?? k
    }
}

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

    /// Birden fazla deste — Mix (P7) bunu deste başına kuyruk kurmak için kullanıyor.
    func cardsByDeck(
        in deckIDs: [String],
        difficulty: CardDifficultyFilter = .all
    ) -> [String: [Card]] {
        var result: [String: [Card]] = [:]
        for id in deckIDs {
            let cards = cards(in: id, difficulty: difficulty)
            if !cards.isEmpty { result[id] = cards }
        }
        return result
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

// MARK: - Havuz

/// §09 §4: oturum içi tekrar engellenir; havuz bitince **yeniden karıştırılıp**
/// açılır ve `didWrap` bir kez `true` olur — ekranda `DESTE BAŞA DÖNDÜ`
/// etiketini gösterecek olan sinyal bu. Etiketin kendisi oyun ekranında (P4).
struct WordPool {
    private var queue: [Card]
    private let source: [Card]

    /// Havuz en az bir kez başa döndü mü.
    private(set) var didWrap = false

    init(cards: [Card]) {
        source = cards
        queue = cards.shuffled()
    }

    var isEmpty: Bool { source.isEmpty }
    var remaining: Int { queue.count }
    var total: Int { source.count }

    /// §09 §4: kalan kart 10'un altına düşse bile sessizce devam edilir, uyarı yok.
    var isRunningLow: Bool { !isEmpty && remaining < 10 }

    mutating func next() -> Card? {
        guard !source.isEmpty else { return nil }
        if queue.isEmpty {
            queue = source.shuffled()
            didWrap = true
        }
        return queue.popLast()
    }

    /// Tur yeniden başlatıldığında havuz tazelenir (§09 §3).
    mutating func reset() {
        queue = source.shuffled()
        didWrap = false
    }
}

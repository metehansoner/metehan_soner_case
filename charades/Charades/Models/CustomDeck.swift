import Foundation
import SwiftData

// MARK: - Limitler

/// §05 §7 tablosu + §09 §4'ün tavsiye satırı.
/// SwiftData modelleri MainActor dışında da yaşayabildiği için limitler
/// `nonisolated` — aksi hâlde Swift 6 varsayılan izolasyonu init'i kırıyor.
enum CustomDeckLimits: Sendable {
    nonisolated static let maxNameLength = 24
    nonisolated static let maxWords = 100
    /// Oynamak için gereken minimum.
    nonisolated static let minWordsToPlay = 5
    /// §09 §4: "60 saniyelik bir turda ~15 kelime geçiyor." Engel değil, tavsiye.
    nonisolated static let recommendedWordCount = 20

    /// Ücretsizde 1 taslak (oynanamaz), Premium'da 3.
    nonisolated static func maxDeckCount(isPremium: Bool) -> Int { isPremium ? 3 : 1 }
}

/// §05 §7: 12 hazır tema afişi. Ham `rawValue` SwiftData'da saklanıyor —
/// isimler değişse de sıra (0…11) sabit kalmalı.
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

    /// §05 §7: kaydedilen sepete şablon **deterministik** atanır — aynı isim aynı
    /// kapağı alır. Rastgele olsaydı kullanıcı aynı sepeti iki kez kaydettiğinde
    /// farklı kapak görürdü.
    nonisolated static func deterministic(for name: String) -> CustomDeckCover {
        let all = allCases
        return all[Int(name.stableHash % UInt64(all.count))]
    }
}

private extension String {
    /// FNV-1a. Swift'in `hashValue`'su süreç başına rastgeleleştiği için
    /// kalıcı bir atama üretmiyor.
    nonisolated var stableHash: UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }
}

// MARK: - SwiftData şeması

/// §05 §7: `UserDefaults`'a JSON gömmekten daha temiz; sıralama ve silme kolay.
///
/// iCloud senkronizasyonu v1'de kapalı (`.none`) ama şema hazır tutuluyor:
/// CloudKit'in şartları — her alanın varsayılan değeri var, `.unique` kısıtı yok,
/// ilişkiler opsiyonel ve ters ilişkisi tanımlı — baştan sağlanıyor. Sonradan
/// açmak `ModelConfiguration`'da tek satır olacak.
@Model
final class CustomDeck {
    var uuid: UUID = UUID()
    var name: String = ""
    /// `CustomDeckCover.rawValue`. Ham int tutuluyor; CloudKit enum bilmiyor.
    var coverTemplate: Int = 0
    /// Premium'da Photos'tan seçilen görsel (sepia + grain + altın çerçeve
    /// uygulanmış hâli). Şablon kullanılıyorsa `nil`.
    var coverImageData: Data?
    /// §05 §7: custom kelimeler çevrilmez, kullanıcının yazdığı dilde kalır.
    /// Deste kartında `TR` gibi küçük bir etiket olarak görünüyor.
    var languageCode: String = "en"
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    /// Izgaradaki sıra; kullanıcı sürükleyerek değiştirebiliyor.
    var sortIndex: Int = 0
    /// Kelime Sepeti'nden kaydedilmiş mi (§05 §7'deki iki kapıdan hangisi).
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
        // Kelimeler burada üretilmiyor: context'e girmeden kurulan `CustomCard`
        // ilişkisi diske yazılmıyor. Çağıran `insert` + `replaceWords` yapıyor.
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

    /// Adsız ve kelimesiz taslak — editör açıkken DB'de duruyor ama ana
    /// ızgarada / listede iz bırakmamalı (`discardIfEmpty` ile aynı kural).
    var hasListableContent: Bool {
        wordCount > 0
            || !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// §09 §4: 20 kelimenin altında bilgi satırı gösteriliyor.
    var isBelowRecommended: Bool { wordCount < CustomDeckLimits.recommendedWordCount }

    /// Custom kartlar oyun döngüsüne katalog kartlarıyla aynı tipte giriyor;
    /// `d = 0` oldukları için zorluk filtresinden muaf kalıyorlar (§09 §4).
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

    /// Kelime listesi tek yerden yazılıyor: `order` her seferinde yeniden
    /// numaralanmazsa silme sonrası boşluklar `toCards()` anahtarlarını çakıştırır.
    ///
    /// Mevcut satırlar yeniden kullanılıp fazlası **açıkça siliniyor**: ilişkiden
    /// çıkarılan `CustomCard` depoda öksüz kalıyor (cascade yalnızca deste
    /// silinince işliyor) ve her kelime eklemede birikirdi.
    ///
    /// Yeni kartlar `modelContext.insert` ile bağlanıyor — yalnızca diziye
    /// eklemek SwiftData'da kalıcı ilişki kurmayabiliyor.
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

// MARK: - Container

enum CustomDeckStore {
    static let schema = Schema([CustomDeck.self, CustomCard.self, SavedMix.self])

    /// §05 §7: iCloud v1'de yok — `.none`. Şema açmaya hazır.
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            // Şema migrate edilemiyorsa bellek içi container'la açılıyor:
            // custom desteler kaybolur ama uygulama açılmayı reddetmez.
            assertionFailure("SwiftData container açılamadı: \(error)")
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: fallback)
        }
    }
}

extension ModelContext {
    /// Autosave'e güvenmek çökme / hızlı kill'de kayıp bırakıyor; kayıt
    /// noktalarında açıkça flush ediyoruz.
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

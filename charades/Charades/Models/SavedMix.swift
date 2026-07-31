import Foundation
import SwiftData

/// §05 §6: Mix sınırları.
enum MixLimits: Sendable {
    /// Min 2, max 8 deste. 8'den fazlası kelime çeşitliliğini anlamsızlaştırıyor
    /// ve kurulum ekranını yönetilemez yapıyor.
    nonisolated static let deckRange = 2...8
    /// Kaydedilebilecek karışım sayısı.
    nonisolated static let maxSaved = 5
    nonisolated static let maxNameLength = 24
}

/// §05 §6: isimlendirilip kaydedilen karışım ("Cuma Gecesi Karışımı").
/// Ana ekranda `BENİM DESTELERİM` bölümünde kolaj kapaklı bir kart olarak
/// görünüyor; tekrar oynama oranını artıran küçük özellik.
///
/// Depolama custom destelerle aynı yerde (§05 §7 `SwiftData`): karışım da
/// kullanıcının ürettiği, sıralanan ve silinen bir içerik. CloudKit v1'de
/// kapalı ama şema hazır — bu yüzden her alanın varsayılanı var, `.unique` yok.
@Model
final class SavedMix {
    var uuid: UUID = UUID()
    var name: String = ""
    /// Seçim sırası korunuyor; kolaj kapağı ilk dört desteden çiziliyor.
    var deckIDs: [String] = []
    var createdAt: Date = Date.now
    /// Izgaradaki sıra; yeni karışım en başa geliyor.
    var sortIndex: Int = 0

    init(name: String, deckIDs: [String], sortIndex: Int = 0) {
        uuid = UUID()
        self.name = String(name.prefix(MixLimits.maxNameLength))
        self.deckIDs = Array(deckIDs.prefix(MixLimits.deckRange.upperBound))
        self.sortIndex = sortIndex
        createdAt = .now
    }

    /// Katalogdan düşen (ör. sezonu kapanan) deste karışımı bozmasın diye
    /// kapak ve sayaçlar her zaman çözülebilen destelerden hesaplanıyor.
    /// Katalog `MainActor`'da yaşıyor, `@Model` ise izole değil — bu yüzden
    /// katalogla konuşan türetmeler açıkça işaretleniyor.
    @MainActor
    var decks: [DeckDef] { deckIDs.compactMap(DeckCatalog.deck) }

    @MainActor
    var cardCount: Int {
        deckIDs.reduce(0) { $0 + (DeckCardCounts.count(for: $1) ?? 0) }
    }

    /// Karışımdaki desteler hâlâ 2'nin altına düşmediyse oynanabilir.
    @MainActor
    var isPlayable: Bool {
        decks.count >= MixLimits.deckRange.lowerBound
    }
}

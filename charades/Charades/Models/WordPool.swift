import Foundation

/// Tur boyunca kart dağıtan havuz.
///
/// §05 §6: birden fazla deste **birleştirilip karıştırılmıyor**. Naif yaklaşım
/// 300 kartlık desteyle 60 kartlığı karıştırınca küçük destenin kelimelerini
/// görünmez yapıyor. Bunun yerine ağırlıklı round-robin: her destenin kendi
/// karıştırılmış kuyruğu var ve çekim sırasında desteler **eşit olasılıkla**
/// seçiliyor. Ağırlık kullanıcıya gösterilmiyor, sadece eşit davranıyor.
///
/// §09 §4: oturum içi tekrar engelleniyor — bir kart, havuzun tamamı bitmeden
/// ikinci kez gelmiyor. Havuz bitince yeniden karıştırılıp açılıyor ve
/// `didWrap` bir kez `true` oluyor; `DESTE BAŞA DÖNDÜ` etiketinin sinyali bu.
struct WordPool {
    private var queues: [[Card]]
    private let sources: [[Card]]

    /// Havuz en az bir kez başa döndü mü.
    private(set) var didWrap = false

    init(cards: [Card]) {
        self.init(byDeck: [cards])
    }

    /// Deste başına ayrılmış kartlar; boş desteler düşüyor.
    init(byDeck decks: [[Card]]) {
        sources = decks.filter { !$0.isEmpty }
        queues = sources.map { $0.shuffled() }
    }

    var isEmpty: Bool { sources.isEmpty }
    var remaining: Int { queues.reduce(0) { $0 + $1.count } }
    var total: Int { sources.reduce(0) { $0 + $1.count } }
    var deckCount: Int { sources.count }

    /// §09 §4: kalan kart 10'un altına düşse bile sessizce devam edilir, uyarı yok.
    var isRunningLow: Bool { !isEmpty && remaining < 10 }

    mutating func next() -> Card? {
        guard !sources.isEmpty else { return nil }
        if remaining == 0 {
            refill()
            didWrap = true
        }
        // Tükenen deste turdan düşüyor; kalanlar arasında eşit olasılık sürüyor.
        // Böylece küçük deste erken bitse bile tekrar başlamıyor, büyük destenin
        // taze kartları önce tükeniyor.
        guard let pick = queues.indices.filter({ !queues[$0].isEmpty }).randomElement() else {
            return nil
        }
        return queues[pick].popLast()
    }

    /// Tur yeniden başlatıldığında havuz tazelenir (§09 §3).
    mutating func reset() {
        refill()
        didWrap = false
    }

    private mutating func refill() {
        queues = sources.map { $0.shuffled() }
    }
}

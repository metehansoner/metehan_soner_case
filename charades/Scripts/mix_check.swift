// Mix karıştırma algoritmasını cihazsız doğrular
// (05-desteler-ve-kategoriler.md §6, 09-kesinti-ve-sinir-durumlari.md §4).
//
// Buradaki iddia gözle görülmüyor: 300 kartlık deste 60 kartlıkla
// karıştırıldığında küçük destenin kelimeleri de gelmeli. Ekranda test etmek
// için yüzlerce kart çevirmek gerekir, o yüzden havuz doğrudan sürülüyor.

import Foundation

var failures = 0

func check(_ label: String, _ condition: Bool, _ detail: String = "") {
    if condition {
        print("  ✓ \(label)")
    } else {
        failures += 1
        print("  ✗ \(label)\(detail.isEmpty ? "" : " — \(detail)")")
    }
}

func deck(_ prefix: String, _ count: Int) -> [Card] {
    (0..<count).map { Card(k: "\(prefix).\($0)", t: ["tr": "\(prefix) \($0)"], d: 0) }
}

func deckName(of card: Card) -> String {
    String(card.k.prefix(while: { $0 != "." }))
}

print("Tek deste")
do {
    var pool = WordPool(cards: deck("a", 20))
    check("toplam kart sayısı", pool.total == 20)
    let drawn = (0..<20).compactMap { _ in pool.next() }
    check("havuz bitmeden tekrar yok", Set(drawn.map(\.k)).count == 20)
    check("başa dönmedi", !pool.didWrap)
    _ = pool.next()
    check("21. kartta başa döndü", pool.didWrap)
}

print("Büyük ve küçük deste birlikte")
do {
    // Naif yaklaşım (birleştir + karıştır) burada ~%17 verirdi.
    var pool = WordPool(byDeck: [deck("big", 300), deck("small", 60)])
    let drawn = (0..<100).compactMap { _ in pool.next() }
    let smallShare = Double(drawn.filter { deckName(of: $0) == "small" }.count) / 100

    check(
        "küçük deste payı ~%50",
        (0.35...0.65).contains(smallShare),
        "ölçülen %\(Int(smallShare * 100))"
    )
    check("100 çekimde tekrar yok", Set(drawn.map(\.k)).count == 100)
    check("başa dönmedi", !pool.didWrap)
}

print("Küçük deste tükendiğinde")
do {
    var pool = WordPool(byDeck: [deck("big", 300), deck("small", 10)])
    let drawn = (0..<200).compactMap { _ in pool.next() }
    let smallCount = drawn.filter { deckName(of: $0) == "small" }.count

    // Tükenen deste turdan düşüyor; erken başa sarıp tekrar üretmiyor.
    check("küçük deste en fazla kart sayısı kadar geldi", smallCount == 10)
    check("tekrar yok", Set(drawn.map(\.k)).count == 200)
    check("büyük deste hâlâ dolu", !pool.didWrap)
}

print("Havuzun tamamı bitince")
do {
    var pool = WordPool(byDeck: [deck("a", 5), deck("b", 3)])
    check("toplam", pool.total == 8)
    let first = (0..<8).compactMap { _ in pool.next() }
    check("iki destenin tamamı geldi", Set(first.map(\.k)).count == 8)
    check("son karta kadar başa dönmedi", !pool.didWrap)

    let extra = pool.next()
    check("başa döndü", pool.didWrap)
    check("kart gelmeye devam ediyor", extra != nil)

    pool.reset()
    check("reset başa dönüş bayrağını temizliyor", !pool.didWrap)
    check("reset havuzu dolduruyor", pool.remaining == 8)
}

print("Sınır durumları")
do {
    var empty = WordPool(byDeck: [])
    check("boş havuz", empty.isEmpty && empty.next() == nil)

    var partial = WordPool(byDeck: [deck("a", 4), [], deck("c", 4)])
    check("boş deste düşüyor", partial.deckCount == 2)
    check("kalan kart", partial.remaining == 8)
    check("az kaldı eşiği", partial.isRunningLow)
    _ = partial.next()
    check("çekim sonrası kalan", partial.remaining == 7)
}

if failures == 0 {
    print("\nTüm kontroller geçti.")
} else {
    print("\n\(failures) kontrol başarısız.")
    exit(1)
}

import Foundation

// Kelime listesi kurallarını cihazsız doğrular
// (05-desteler-ve-kategoriler.md §7, 02-ekran-akisi.md §24).

var failures = 0

func check(_ label: String, _ condition: Bool) {
    print("\(condition ? "✓" : "✗") \(label)")
    if !condition { failures += 1 }
}

let limit = 100

// 1 — Yeni kelime listenin başına giriyor (§02 §24: yazdığını görmeli).
let first = WordList.inserting("Terfi", into: ["Zoom"], limit: limit)
check("yeni kelime başa giriyor", first.words == ["Terfi", "Zoom"])

// 2 — Baştaki/sondaki ve satır içi fazla boşluk temizleniyor.
let spaced = WordList.inserting("  kahve   molası ", into: [], limit: limit)
check("boşluklar normalleşiyor", spaced.words == ["kahve molası"])

// 3 — Tekrar eden kelime eklenmiyor, mevcut satırın index'i dönüyor.
let duplicate = WordList.inserting("zoom", into: ["Terfi", "Zoom"], limit: limit)
check("tekrar eklenmiyor", duplicate.words.count == 2 && duplicate.addedCount == 0)
check("tekrar eden satır işaretleniyor", duplicate.duplicateIndex == 1)

// 4 — Aksan ve Türkçe büyük/küçük harf farkı tekrar sayılıyor.
let folded = WordList.inserting("istanbul", into: ["İstanbul"], limit: limit)
check("aksan/harf farkı tekrar sayılıyor", folded.duplicateIndex == 0)

// 5 — Boş giriş sessizce yutuluyor.
let blank = WordList.inserting("   ", into: ["Zoom"], limit: limit)
check("boş giriş eklenmiyor", blank.words == ["Zoom"] && blank.duplicateIndex == nil)

// 6 — Limit dolunca ekleme durup bayrak kalkıyor.
let full = (1...limit).map { "kelime \($0)" }
let overflow = WordList.inserting("yeni", into: full, limit: limit)
check("limit dolunca eklenmiyor", overflow.words.count == limit && overflow.hitLimit)

// 7 — Toplu ekleme satır, virgül ve noktalı virgülle ayırıyor.
let parsed = WordList.parse("Toplantı\nKahve molası, Terfi; Mesai\n\n  ")
check("toplu ayraçlar", parsed == ["Toplantı", "Kahve molası", "Terfi", "Mesai"])

// 8 — Yapıştırılan blok kendi içindeki tekrarları da eliyor.
let merged = WordList.merging("Zoom, zoom, Mesai", into: ["Terfi"], limit: limit)
check("blok içi tekrar eleniyor", merged.words == ["Mesai", "Zoom", "Terfi"])
check("eklenen sayısı doğru", merged.addedCount == 2)

// 9 — Blok limiti aşarsa sığan kadarı giriyor.
let nearFull = (1...(limit - 2)).map { "kelime \($0)" }
let capped = WordList.merging("a, b, c, d", into: nearFull, limit: limit)
check("blok limitte kesiliyor", capped.words.count == limit && capped.hitLimit)
check("sığan kadarı eklendi", capped.addedCount == 2)

print(failures == 0 ? "\nTüm kontroller geçti." : "\n\(failures) kontrol başarısız.")
exit(failures == 0 ? 0 : 1)

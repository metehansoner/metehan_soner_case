import Foundation


var failures = 0

func check(_ label: String, _ condition: Bool) {
    print("\(condition ? "✓" : "✗") \(label)")
    if !condition { failures += 1 }
}

let limit = 100


let first = WordList.inserting("Terfi", into: ["Zoom"], limit: limit)
check("yeni kelime başa giriyor", first.words == ["Terfi", "Zoom"])


let spaced = WordList.inserting("  kahve   molası ", into: [], limit: limit)
check("boşluklar normalleşiyor", spaced.words == ["kahve molası"])


let duplicate = WordList.inserting("zoom", into: ["Terfi", "Zoom"], limit: limit)
check("tekrar eklenmiyor", duplicate.words.count == 2 && duplicate.addedCount == 0)
check("tekrar eden satır işaretleniyor", duplicate.duplicateIndex == 1)


let folded = WordList.inserting("istanbul", into: ["İstanbul"], limit: limit)
check("aksan/harf farkı tekrar sayılıyor", folded.duplicateIndex == 0)


let blank = WordList.inserting("   ", into: ["Zoom"], limit: limit)
check("boş giriş eklenmiyor", blank.words == ["Zoom"] && blank.duplicateIndex == nil)


let full = (1...limit).map { "kelime \($0)" }
let overflow = WordList.inserting("yeni", into: full, limit: limit)
check("limit dolunca eklenmiyor", overflow.words.count == limit && overflow.hitLimit)


let parsed = WordList.parse("Toplantı\nKahve molası, Terfi; Mesai\n\n  ")
check("toplu ayraçlar", parsed == ["Toplantı", "Kahve molası", "Terfi", "Mesai"])


let merged = WordList.merging("Zoom, zoom, Mesai", into: ["Terfi"], limit: limit)
check("blok içi tekrar eleniyor", merged.words == ["Mesai", "Zoom", "Terfi"])
check("eklenen sayısı doğru", merged.addedCount == 2)


let nearFull = (1...(limit - 2)).map { "kelime \($0)" }
let capped = WordList.merging("a, b, c, d", into: nearFull, limit: limit)
check("blok limitte kesiliyor", capped.words.count == limit && capped.hitLimit)
check("sığan kadarı eklendi", capped.addedCount == 2)

print(failures == 0 ? "\nTüm kontroller geçti." : "\n\(failures) kontrol başarısız.")
exit(failures == 0 ? 0 : 1)

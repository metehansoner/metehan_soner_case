import Foundation

/// Kelime listesi kuralları — 05-desteler-ve-kategoriler.md §7 ve
/// 02-ekran-akisi.md §24. Custom deste editörü ile Kelime Sepeti aynı giriş
/// bileşenini paylaştığı için kurallar da tek yerde: iki ekranda "aynı kelimeyi
/// iki kez ekledim" davranışının farklı olması kullanıcıya hata gibi görünür.
enum WordList {
    /// §02 §24: eklenen kelime listenin **başına** giriyor — kullanıcı yazdığını
    /// görmeli, listenin dibine düşen kelime yazıldı mı belli olmuyor.
    struct Insertion {
        var words: [String]
        /// Zaten varsa eklenmiyor; bu satır bir an amber yanıyor (uyarı metni yok).
        var duplicateIndex: Int?
        var addedCount = 0
        /// Limit doldu, kalanlar alınmadı.
        var hitLimit = false
    }

    /// Baştaki/sondaki boşluk ve satır içi tekrarlı boşluklar temizleniyor;
    /// "kahve   molası" ile "kahve molası" aynı kelime.
    static func normalized(_ raw: String) -> String {
        raw.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// Tekrar kontrolü büyük/küçük harf ve aksandan bağımsız: "İstanbul" ile
    /// "istanbul" aynı kelime. Türkçe i/İ için locale duyarlı katlama şart.
    static func index(of word: String, in words: [String]) -> Int? {
        let key = foldKey(word)
        return words.firstIndex { foldKey($0) == key }
    }

    static func inserting(_ raw: String, into words: [String], limit: Int) -> Insertion {
        let word = normalized(raw)
        guard !word.isEmpty else { return Insertion(words: words) }
        if let existing = index(of: word, in: words) {
            return Insertion(words: words, duplicateIndex: existing)
        }
        guard words.count < limit else { return Insertion(words: words, hitLimit: true) }
        return Insertion(words: [word] + words, addedCount: 1)
    }

    /// §05 §7 toplu ekleme: satır ya da virgülle ayrılıyor. Noktalı virgül de
    /// kabul ediliyor — Excel'den yapıştıran kullanıcı onu üretiyor.
    static func parse(_ bulk: String) -> [String] {
        bulk
            .split(whereSeparator: { $0 == "\n" || $0 == "," || $0 == ";" })
            .map { normalized(String($0)) }
            .filter { !$0.isEmpty }
    }

    /// Yapıştırılan blok tek tek ekleniyor: kendi içindeki tekrarlar da eleniyor.
    static func merging(_ bulk: String, into words: [String], limit: Int) -> Insertion {
        var result = Insertion(words: words)
        for word in parse(bulk) {
            let step = inserting(word, into: result.words, limit: limit)
            result.words = step.words
            result.addedCount += step.addedCount
            if step.hitLimit {
                result.hitLimit = true
                break
            }
        }
        return result
    }

    private static func foldKey(_ word: String) -> String {
        word.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

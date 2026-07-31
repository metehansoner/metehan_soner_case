import Foundation

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

    /// §05 §7: custom kelimeler çevrilmiyor, kullanıcının yazdığı dilde kalıyor.
    /// Metin `en`e de yazılıyor: kullanıcı TR yazıp uygulamayı İngilizce'ye
    /// alırsa `text(for:)` ham anahtara düşer ve oyun kartında `custom.…` çıkardı.
    nonisolated static func custom(key: String, text: String, language: String) -> Card {
        // Sözlük literali kullanılmıyor: dil zaten `en` olduğunda çift anahtar
        // oluşuyor ve `Dictionary(dictionaryLiteral:)` çalışma anında çöküyor.
        var translations = ["en": text]
        translations[language] = text
        return Card(k: key, t: translations, d: 0)
    }
}

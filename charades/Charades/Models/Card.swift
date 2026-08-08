import Foundation


struct Card: Codable, Hashable, Identifiable, Sendable {

    let k: String


    let t: [String: String]


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


    nonisolated func text(for language: String) -> String {
        t[language] ?? t["en"] ?? k
    }


    nonisolated static func custom(key: String, text: String, language: String) -> Card {


        var translations = ["en": text]
        translations[language] = text
        return Card(k: key, t: translations, d: 0)
    }
}

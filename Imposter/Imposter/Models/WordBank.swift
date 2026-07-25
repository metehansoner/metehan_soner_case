import Foundation

struct SecretEntry: Hashable {
    let word: String
    let hint: String
}

enum WordBank {
    private static let catalog: [String: [[String: [String: String]]]] = {
        let url =
            Bundle.main.url(forResource: "words", withExtension: "json", subdirectory: "Resources/WordBank")
            ?? Bundle.main.url(forResource: "words", withExtension: "json", subdirectory: "WordBank")
            ?? Bundle.main.url(forResource: "words", withExtension: "json")
        guard let url,
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [[String: [String: String]]]].self, from: data)
        else {
            return [:]
        }
        return decoded
    }()

    static func randomWord(categoryIDs: Set<String>, locale: String = LocalizationManager.shared.localeCode) -> SecretEntry {
        let pool = categoryIDs.flatMap { entries(for: $0, locale: locale) }
        let fallback = entries(for: "party", locale: locale)
        return (pool.isEmpty ? fallback : pool).randomElement()
            ?? SecretEntry(word: "Party", hint: "Celebrate")
    }

    private static func entries(for categoryID: String, locale: String) -> [SecretEntry] {
        guard let rows = catalog[categoryID] else { return [] }
        return rows.compactMap { row in
            guard let wordMap = row["word"], let hintMap = row["hint"] else { return nil }
            let word = localized(wordMap, locale: locale)
            let hint = localized(hintMap, locale: locale)
            guard !word.isEmpty else { return nil }
            return SecretEntry(word: word, hint: hint.isEmpty ? "…" : hint)
        }
    }

    private static func localized(_ map: [String: String], locale: String) -> String {
        map[locale] ?? map["en"] ?? map.values.first ?? ""
    }
}

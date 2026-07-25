import Foundation

struct SecretEntry: Hashable {
    let word: String
    let hint: String
    /// Stable English key for session de-duplication across locales.
    let englishKey: String
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

    /// Picks a random word from selected categories, skipping English keys in `excluding`.
    /// When every candidate was used, the pool recycles (excluding is ignored for that pick).
    static func randomWord(
        categoryIDs: Set<String>,
        locale: String = LocalizationManager.shared.localeCode,
        excluding: Set<String> = []
    ) -> SecretEntry {
        let pool = categoryIDs.flatMap { entries(for: $0, locale: locale) }
        let fallback = entries(for: "party", locale: locale)
        let source = pool.isEmpty ? fallback : pool
        let available = source.filter { !excluding.contains($0.englishKey) }
        return (available.isEmpty ? source : available).randomElement()
            ?? SecretEntry(word: "Party", hint: "Celebrate", englishKey: "Party")
    }

    private static func entries(for categoryID: String, locale: String) -> [SecretEntry] {
        guard let rows = catalog[categoryID] else { return [] }
        return rows.compactMap { row in
            guard let wordMap = row["word"], let hintMap = row["hint"] else { return nil }
            let englishKey = wordMap["en"] ?? ""
            let word = localized(wordMap, locale: locale)
            let hint = localized(hintMap, locale: locale)
            guard !word.isEmpty, !englishKey.isEmpty else { return nil }
            return SecretEntry(
                word: word,
                hint: hint.isEmpty ? "…" : hint,
                englishKey: englishKey
            )
        }
    }

    private static func localized(_ map: [String: String], locale: String) -> String {
        map[locale] ?? map["en"] ?? map.values.first ?? ""
    }
}

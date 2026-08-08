import Foundation


enum WordList {


    struct Insertion {
        var words: [String]

        var duplicateIndex: Int?
        var addedCount = 0

        var hitLimit = false
    }


    static func normalized(_ raw: String) -> String {
        raw.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }


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


    static func parse(_ bulk: String) -> [String] {
        bulk
            .split(whereSeparator: { $0 == "\n" || $0 == "," || $0 == ";" })
            .map { normalized(String($0)) }
            .filter { !$0.isEmpty }
    }


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

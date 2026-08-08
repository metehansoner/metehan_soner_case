import Foundation


struct WordPool {
    private var queues: [[Card]]
    private let sources: [[Card]]


    private(set) var didWrap = false

    init(cards: [Card]) {
        self.init(byDeck: [cards])
    }


    init(byDeck decks: [[Card]]) {
        sources = decks.filter { !$0.isEmpty }
        queues = sources.map { $0.shuffled() }
    }

    var isEmpty: Bool { sources.isEmpty }
    var remaining: Int { queues.reduce(0) { $0 + $1.count } }
    var total: Int { sources.reduce(0) { $0 + $1.count } }
    var deckCount: Int { sources.count }


    var isRunningLow: Bool { !isEmpty && remaining < 10 }

    mutating func next() -> Card? {
        guard !sources.isEmpty else { return nil }
        if remaining == 0 {
            refill()
            didWrap = true
        }


        guard let pick = queues.indices.filter({ !queues[$0].isEmpty }).randomElement() else {
            return nil
        }
        return queues[pick].popLast()
    }


    mutating func reset() {
        refill()
        didWrap = false
    }

    private mutating func refill() {
        queues = sources.map { $0.shuffled() }
    }
}

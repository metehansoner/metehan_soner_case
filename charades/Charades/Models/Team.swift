import Foundation


struct Team: Identifiable, Hashable, Sendable {


    static let countRange = 2...4
    static let playerLimit = 8


    static let roundsRange = 1...5
    static let defaultRounds = 3

    let id: UUID
    var name: String
    var players: [String]

    init(id: UUID = UUID(), name: String = "", players: [String] = []) {
        self.id = id
        self.name = name
        self.players = players
    }


    var namedPlayers: [String] {
        players
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }


    func player(forTurn turn: Int) -> String? {
        let named = namedPlayers
        guard !named.isEmpty else { return nil }
        return named[turn % named.count]
    }


    func resolvingName(order: Int, numbered: (Int) -> String) -> Team {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var copy = self
        copy.name = trimmed.isEmpty ? numbered(order + 1) : trimmed
        copy.players = namedPlayers
        return copy
    }

    static var defaultRoster: [Team] {
        (0..<countRange.lowerBound).map { _ in Team() }
    }
}

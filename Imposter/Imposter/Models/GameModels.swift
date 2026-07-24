import Foundation

struct Player: Identifiable, Equatable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String = "") {
        self.id = id
        self.name = name
    }
}

enum PlayerLimits {
    static let minCount = 3
    static let maxCount = 15
}

enum RoundDurationLimits {
    static let minSeconds = 30
    static let maxSeconds = 5 * 60
    static let stepSeconds = 30
    static let defaultSeconds = 120
}

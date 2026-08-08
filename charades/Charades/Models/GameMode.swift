import Foundation


enum GameMode: String, CaseIterable, Identifiable, Sendable {
    case classic
    case teams
    case actOut
    case rapid
    case mix
    case ownWords

    var id: String { rawValue }


    var titleKey: String { "mode.\(rawValue).title" }
    var subtitleKey: String { "mode.\(rawValue).subtitle" }


    var systemImage: String {
        switch self {
        case .classic: "movieclapper"
        case .teams: "chart.bar.fill"
        case .actOut: "figure.arms.open"
        case .rapid: "bolt.fill"
        case .mix: "shuffle"
        case .ownWords: "text.bubble.fill"
        }
    }


    var isFree: Bool { self == .classic }


    var howToSeenKey: String { self == .mix ? GameMode.classic.rawValue : rawValue }


    var usesTilt: Bool { true }

    var usesTeams: Bool { self == .teams }


    var perWordLimit: TimeInterval? { self == .rapid ? 5 : nil }


    var screenVisibleToGuesser: Bool { self != .actOut }

    var scoreMultiplier: Int { self == .rapid ? 2 : 1 }


    var needsDeckSelection: Bool { self != .ownWords }


    var defaultDuration: Int {
        switch self {
        case .actOut: 90
        case .rapid: 30
        default: 60
        }
    }


    var isDurationLocked: Bool { self == .rapid }


    var usesOwnDuration: Bool { self == .actOut || self == .rapid }


    static let durationRange = 30...180
    static let durationStep = 15
}


enum AnswerInput: String, Sendable {
    case tilt
    case touch
}

import SwiftUI


enum DeckSection: String, CaseIterable, Identifiable, Sendable {
    case party
    case actOut
    case movieTV
    case music
    case kids
    case sports
    case knowledge
    case brands
    case nostalgia
    case world
    case animals
    case home
    case seasonal

    var id: String { rawValue }

    var titleKey: String { "section.\(rawValue).title" }


    var dominantHex: UInt32 {
        switch self {
        case .party: 0xF0A93B
        case .actOut: 0x2F7F7C
        case .movieTV: 0x2B0E15
        case .music: 0xA8791F
        case .kids: 0xF4E7CE
        case .sports: 0x4F8F5B
        case .knowledge: 0x2F7F7C
        case .brands: 0xE3C36A
        case .nostalgia: 0xD2861F
        case .world: 0x2F7F7C
        case .animals: 0x4F8F5B
        case .home: 0xE8D3A9
        case .seasonal: 0xC0392B
        }
    }

    var dominantTone: Color { Color(hex: dominantHex) }


    var meterTone: Color { Color.scaling(hex: dominantHex, minimumChannel: 0.62).color }


    var artGradient: EllipticalGradient {
        let inner = Color.scaling(hex: dominantHex, minimumChannel: 0.45)
        return EllipticalGradient(
            gradient: Gradient(stops: [
                .init(color: inner.color, location: 0),
                .init(color: inner.scaled(by: 0.42), location: 0.62),
                .init(color: inner.scaled(by: 0.16), location: 1),
            ]),
            center: UnitPoint(x: 0.5, y: 0.34),
            startRadiusFraction: 0,
            endRadiusFraction: 0.78
        )
    }


    var isDateGated: Bool { self == .seasonal }
}


enum DeckFilter: Hashable, Identifiable, Sendable {
    case all
    case popular
    case new
    case favorites
    case section(DeckSection)

    var id: String {
        switch self {
        case .all: "all"
        case .popular: "popular"
        case .new: "new"
        case .favorites: "favorites"
        case .section(let s): "section.\(s.rawValue)"
        }
    }

    var titleKey: String {
        switch self {
        case .all: "filter.all"
        case .popular: "filter.popular"
        case .new: "filter.new"
        case .favorites: "filter.favorites"
        case .section(let s): "filter.section.\(s.rawValue)"
        }
    }


    static let standardOrder: [DeckFilter] =
        [.all, .popular, .new] + DeckSection.allCases.map(DeckFilter.section)
}

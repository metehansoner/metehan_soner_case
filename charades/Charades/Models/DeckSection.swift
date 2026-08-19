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

    var symbolName: String {
        switch self {
        case .party: "party.popper.fill"
        case .actOut: "theatermasks.fill"
        case .movieTV: "film.fill"
        case .music: "music.note"
        case .kids: "teddybear.fill"
        case .sports: "soccerball"
        case .knowledge: "lightbulb.fill"
        case .brands: "tag.fill"
        case .nostalgia: "clock.arrow.circlepath"
        case .world: "globe.europe.africa.fill"
        case .animals: "pawprint.fill"
        case .home: "house.fill"
        case .seasonal: "gift.fill"
        }
    }
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

    var symbolName: String {
        switch self {
        case .all: "square.grid.2x2.fill"
        case .popular: "flame.fill"
        case .new: "sparkles"
        case .favorites: "heart.fill"
        case .section(let s): s.symbolName
        }
    }

    var chipAccent: Color {
        switch self {
        case .all: AppColors.accentGold
        case .popular: AppColors.accentAmber
        case .new: Color(hex: 0x4EC4BF)
        case .favorites: AppColors.stateSkip
        case .section(let s): s.meterTone
        }
    }

    var chipFill: LinearGradient {
        switch self {
        case .all:
            LinearGradient(
                colors: [AppColors.accentGold, AppColors.accentBrass],
                startPoint: .top,
                endPoint: .bottom
            )
        case .popular:
            LinearGradient(
                colors: [Color(hex: 0xFFC45A), AppColors.accentAmberDeep],
                startPoint: .top,
                endPoint: .bottom
            )
        case .new:
            LinearGradient(
                colors: [Color(hex: 0x4EC4BF), AppColors.accentTeal],
                startPoint: .top,
                endPoint: .bottom
            )
        case .favorites:
            LinearGradient(
                colors: [Color(hex: 0xE05548), AppColors.stateSkip],
                startPoint: .top,
                endPoint: .bottom
            )
        case .section:
            LinearGradient(
                colors: [AppColors.accentAmber, AppColors.accentAmberDeep],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    var usesDarkChipLabel: Bool {
        switch self {
        case .new, .favorites: false
        case .all, .popular, .section: true
        }
    }

    var chipBulbColor: Color {
        usesDarkChipLabel ? AppColors.surfacePoster : AppColors.accentGold
    }

    var chipLabelColor: Color {
        usesDarkChipLabel ? AppColors.textOnAmber : AppColors.textCream
    }


    static let standardOrder: [DeckFilter] =
        [.all, .popular, .new] + DeckSection.allCases.map(DeckFilter.section)
}

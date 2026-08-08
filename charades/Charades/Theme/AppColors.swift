import SwiftUI


enum AppColors {


    static let bgFilmBlack = Color(hex: 0x100C0A)
    static let bgVelvetDeep = Color(hex: 0x2B0E15)
    static let bgVelvetMid = Color(hex: 0x47161F)
    static let bgVelvetLight = Color(hex: 0x5E1E27)
    static let bgSpotlight = Color(hex: 0x8A4B1E)


    static let surfaceCard = Color(hex: 0x1C1512)
    static let surfaceCardRaised = Color(hex: 0x2A201A)
    static let surfacePoster = Color(hex: 0xF4E7CE)
    static let surfaceTicket = Color(hex: 0xE8D3A9)


    static let accentAmber = Color(hex: 0xF0A93B)
    static let accentAmberDeep = Color(hex: 0xD2861F)
    static let accentGold = Color(hex: 0xE3C36A)
    static let accentBrass = Color(hex: 0xA8791F)
    static let accentTeal = Color(hex: 0x2F7F7C)


    static let stateCorrect = Color(hex: 0x4F8F5B)
    static let stateSkip = Color(hex: 0xC0392B)
    static let stateWarning = Color(hex: 0xE0A030)
    static let stateLocked = Color(hex: 0x6E5B4B)


    static let teamColors: [Color] = [accentAmber, accentTeal, stateSkip, accentGold]

    static func team(_ index: Int) -> Color {
        teamColors[index % teamColors.count]
    }


    static let textCream = Color(hex: 0xF6EBD6)
    static let textSecondary = Color(hex: 0xC6B394)


    static let textMuted = Color(hex: 0x948370)
    static let textOnPoster = Color(hex: 0x1C1512)


    static let textOnPosterMuted = Color(hex: 0x6B5C46)
    static let textOnAmber = Color(hex: 0x201509)


    static let btnPrimaryBg = accentAmber
    static let btnPrimaryText = textOnAmber
    static let btnSecondaryBg = surfaceCardRaised
    static let btnSecondaryBorder = accentGold
    static let btnSecondaryText = textCream
    static let btnDangerBg = stateSkip
    static let btnDisabledBg = Color(hex: 0x33281F)
    static let btnDisabledText = stateLocked
}

extension AppColors {


    static var screenBackground: EllipticalGradient {
        EllipticalGradient(
            colors: [bgVelvetMid, bgVelvetDeep, bgFilmBlack],
            center: .center,
            startRadiusFraction: 0,
            endRadiusFraction: 0.85
        )
    }


    static var spotlightOverlay: EllipticalGradient {
        EllipticalGradient(
            colors: [bgSpotlight.opacity(0.18), .clear],
            center: UnitPoint(x: 0.5, y: -0.05),
            startRadiusFraction: 0,
            endRadiusFraction: 0.7
        )
    }


    static var vignette: EllipticalGradient {
        EllipticalGradient(
            colors: [.clear, bgFilmBlack.opacity(0.45)],
            center: .center,
            startRadiusFraction: 0.35,
            endRadiusFraction: 0.95
        )
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }


    struct Scaled {
        let red: Double
        let green: Double
        let blue: Double

        var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: 1) }

        func scaled(by factor: Double) -> Color {
            Color(.sRGB, red: red * factor, green: green * factor, blue: blue * factor, opacity: 1)
        }
    }


    static func scaling(hex: UInt32, minimumChannel: Double) -> Scaled {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        let peak = max(red, green, blue)
        let factor = peak > 0 ? max(1, minimumChannel / peak) : 1
        return Scaled(red: min(1, red * factor), green: min(1, green * factor), blue: min(1, blue * factor))
    }
}

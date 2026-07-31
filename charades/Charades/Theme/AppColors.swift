import SwiftUI

/// GRAND MARQUEE paleti — 01-tasarim-sistemi.md §1.
/// Renkler asset catalog'da değil burada; tek dosyada tüm paleti görmek ve
/// kod üzerinden türetme (opacity/blend) yapabilmek için.
enum AppColors {

    // MARK: Arka plan katmanları

    static let bgFilmBlack = Color(hex: 0x100C0A)
    static let bgVelvetDeep = Color(hex: 0x2B0E15)
    static let bgVelvetMid = Color(hex: 0x47161F)
    static let bgVelvetLight = Color(hex: 0x5E1E27)
    static let bgSpotlight = Color(hex: 0x8A4B1E)

    // MARK: Yüzeyler

    static let surfaceCard = Color(hex: 0x1C1512)
    static let surfaceCardRaised = Color(hex: 0x2A201A)
    static let surfacePoster = Color(hex: 0xF4E7CE)
    static let surfaceTicket = Color(hex: 0xE8D3A9)

    // MARK: Accent

    static let accentAmber = Color(hex: 0xF0A93B)
    static let accentAmberDeep = Color(hex: 0xD2861F)
    static let accentGold = Color(hex: 0xE3C36A)
    static let accentBrass = Color(hex: 0xA8791F)
    static let accentTeal = Color(hex: 0x2F7F7C)

    // MARK: Durum

    static let stateCorrect = Color(hex: 0x4F8F5B)
    static let stateSkip = Color(hex: 0xC0392B)
    static let stateWarning = Color(hex: 0xE0A030)
    static let stateLocked = Color(hex: 0x6E5B4B)

    // MARK: Metin

    static let textCream = Color(hex: 0xF6EBD6)
    static let textSecondary = Color(hex: 0xC6B394)
    static let textMuted = Color(hex: 0x8B7A66)
    static let textOnPoster = Color(hex: 0x1C1512)
    static let textOnAmber = Color(hex: 0x201509)

    // MARK: Buton

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

    /// §1: merkezde `bgVelvetMid`, kenarlarda `bgFilmBlack`.
    /// Yarıçaplar oran cinsinden; oyun ekranı landscape'e döndüğünde de doğru ölçeklenir.
    static var screenBackground: EllipticalGradient {
        EllipticalGradient(
            colors: [bgVelvetMid, bgVelvetDeep, bgFilmBlack],
            center: .center,
            startRadiusFraction: 0,
            endRadiusFraction: 0.85
        )
    }

    /// §1: üst-orta noktadan gelen sıcak spot halesi, %18 opacity.
    static var spotlightOverlay: EllipticalGradient {
        EllipticalGradient(
            colors: [bgSpotlight.opacity(0.18), .clear],
            center: UnitPoint(x: 0.5, y: -0.05),
            startRadiusFraction: 0,
            endRadiusFraction: 0.7
        )
    }

    /// §3: kenarlarda `bgFilmBlack` %45.
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
}

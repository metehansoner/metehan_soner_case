import SwiftUI
import UIKit

/// Tipografi katmanı — 01-tasarim-sistemi.md §2.
/// Locale kontrolü **yalnızca burada** yapılır; çağrı yerlerinde koşul yazılmaz.
@MainActor
enum AppFont {

    struct Families {
        let display: String
        let accent: String
        let ui: String
    }

    /// Dil değişimi restart gerektirmediği için (§06) font ailesi sabit değil,
    /// her erişimde okunan bir değer. P9'da `LocalizationManager.current` buraya bağlanır.
    static var currentLanguageCode: () -> String = {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    /// §2 "Locale'e göre font ikamesi" tablosu. Oswald ve Playfair'de Arap ve
    /// Yunan glifi yok; Rubik'te Arap var, Yunan yok.
    static var families: Families {
        switch currentLanguageCode() {
        case "ar":
            return Families(display: "Rubik", accent: "Rubik", ui: "Rubik")
        case "el":
            return Families(display: "Fira Sans Condensed", accent: "EB Garamond", ui: "Fira Sans")
        default:
            return Families(display: "Oswald", accent: "Playfair Display", ui: "Rubik")
        }
    }

    /// Bundle'a gömülü PostScript adları. §2'deki glif doğrulama testi bunu kullanır.
    static let bundledPostScriptNames = [
        "Oswald-SemiBold", "Oswald-Bold",
        "PlayfairDisplayRoman-Black", "PlayfairDisplayItalic-BoldItalic",
        "Rubik-Regular", "Rubik-Medium", "Rubik-SemiBold", "Rubik-Bold",
        "FiraSansCondensed-Bold", "FiraSansCondensed-ExtraBold",
        "FiraSans-Regular", "FiraSans-Medium", "FiraSans-SemiBold", "FiraSans-Bold",
        "EBGaramond-Bold", "EBGaramondItalic-BoldItalic",
    ]

    static func isAvailable(_ postScriptName: String) -> Bool {
        UIFont(name: postScriptName, size: 12) != nil
    }

    // MARK: Roller

    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        resolve(role: .display, size: size, weight: weight, italic: false)
    }

    static func accent(_ size: CGFloat, weight: Font.Weight = .black, italic: Bool = false) -> Font {
        resolve(role: .accent, size: size, weight: weight, italic: italic)
    }

    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        resolve(role: .ui, size: size, weight: weight, italic: false)
    }

    private enum Role { case display, accent, ui }

    private static func resolve(role: Role, size: CGFloat, weight: Font.Weight, italic: Bool) -> Font {
        let family: String
        switch role {
        case .display: family = families.display
        case .accent: family = families.accent
        case .ui: family = families.ui
        }

        for name in postScriptCandidates(family: family, weight: weight, italic: italic) {
            if UIFont(name: name, size: size) != nil {
                return .custom(name, size: size)
            }
        }

        if let base = UIFont(name: family, size: size) {
            var traits: UIFontDescriptor.SymbolicTraits = []
            if weight.rank >= Font.Weight.semibold.rank { traits.insert(.traitBold) }
            if italic { traits.insert(.traitItalic) }
            if !traits.isEmpty, let descriptor = base.fontDescriptor.withSymbolicTraits(traits) {
                return Font(UIFont(descriptor: descriptor, size: size))
            }
            return Font(base)
        }

        return .system(size: size, weight: weight, design: role == .accent ? .serif : .default)
    }

    private static func postScriptCandidates(
        family: String,
        weight: Font.Weight,
        italic: Bool
    ) -> [String] {
        let compact = family.replacingOccurrences(of: " ", with: "")

        switch family {
        case "Oswald":
            return weight.rank >= Font.Weight.bold.rank
                ? ["Oswald-Bold", "Oswald-SemiBold"]
                : ["Oswald-SemiBold", "Oswald-Bold"]

        case "Playfair Display":
            return italic
                ? ["PlayfairDisplayItalic-BoldItalic", "PlayfairDisplay-BoldItalic", "PlayfairDisplayRoman-Black"]
                : ["PlayfairDisplayRoman-Black", "PlayfairDisplay-Black", "PlayfairDisplayItalic-BoldItalic"]

        // §2 Yunanca ikamesi. Fira Sans Condensed marquee rolünü, Fira Sans
        // gövdeyi, EB Garamond afiş serif'ini karşılıyor.
        case "Fira Sans Condensed":
            return weight.rank >= Font.Weight.heavy.rank
                ? ["FiraSansCondensed-ExtraBold", "FiraSansCondensed-Bold"]
                : ["FiraSansCondensed-Bold", "FiraSansCondensed-ExtraBold"]

        case "Fira Sans":
            switch weight {
            case .black, .heavy, .bold:
                return ["FiraSans-Bold", "FiraSans-SemiBold"]
            case .semibold:
                return ["FiraSans-SemiBold", "FiraSans-Bold"]
            case .medium:
                return ["FiraSans-Medium", "FiraSans-SemiBold"]
            default:
                return ["FiraSans-Regular", "FiraSans-Medium"]
            }

        // Değişken fonttan sabit ağırlık çıkarılınca italik yüzün PostScript
        // adı `EBGaramondItalic-BoldItalic` oluyor; dosya adıyla eşleşmiyor.
        case "EB Garamond":
            return italic
                ? ["EBGaramondItalic-BoldItalic", "EBGaramond-BoldItalic", "EBGaramond-Bold"]
                : ["EBGaramond-Bold", "EBGaramondItalic-BoldItalic"]

        case "Rubik":
            switch weight {
            case .black, .heavy, .bold:
                return ["Rubik-Bold", "Rubik-SemiBold"]
            case .semibold:
                return ["Rubik-SemiBold", "Rubik-Bold"]
            case .medium:
                return ["Rubik-Medium", "Rubik-SemiBold"]
            default:
                return ["Rubik-Regular", "Rubik-Medium"]
            }

        default:
            let suffix: String
            if weight.rank >= Font.Weight.bold.rank {
                suffix = "Bold"
            } else if weight.rank >= Font.Weight.semibold.rank {
                suffix = "SemiBold"
            } else {
                suffix = "Regular"
            }
            return italic ? ["\(compact)-\(suffix)Italic", "\(compact)-Italic"] : ["\(compact)-\(suffix)"]
        }
    }
}

/// `Font.Weight` Comparable değil; ikame zincirinde "bu ağırlıktan kalın mı"
/// sorusunu sorabilmek için sıralanabilir bir karşılık.
private extension Font.Weight {
    var rank: Int {
        switch self {
        case .ultraLight: return 100
        case .thin: return 200
        case .light: return 300
        case .regular: return 400
        case .medium: return 500
        case .semibold: return 600
        case .bold: return 700
        case .heavy: return 800
        case .black: return 900
        default: return 400
        }
    }
}

/// §2 tip ölçeği. Punto, harf aralığı ve ALL CAPS kararı token'da taşınır;
/// ekranlarda tekrar yazılmaz.
struct AppTextStyle {
    let font: Font
    let tracking: CGFloat
    let textCase: Text.Case?

    init(font: Font, tracking: CGFloat = 0, textCase: Text.Case? = nil) {
        self.font = font
        self.tracking = tracking
        self.textCase = textCase
    }
}

@MainActor
extension AppTextStyle {
    static var marquee: AppTextStyle {
        .init(font: AppFont.display(44, weight: .bold), tracking: 2, textCase: .uppercase)
    }
    static var screenTitle: AppTextStyle {
        .init(font: AppFont.display(28, weight: .bold), tracking: 1.5, textCase: .uppercase)
    }
    static var posterTitle: AppTextStyle {
        .init(font: AppFont.accent(22, weight: .black))
    }
    static func gameWord(_ size: CGFloat = 64) -> AppTextStyle {
        .init(font: AppFont.display(size, weight: .bold), tracking: 1, textCase: .uppercase)
    }
    static var sectionLabel: AppTextStyle {
        .init(font: AppFont.ui(12, weight: .semibold), tracking: 2, textCase: .uppercase)
    }
    static var body: AppTextStyle {
        .init(font: AppFont.ui(16))
    }
    static var bodyStrong: AppTextStyle {
        .init(font: AppFont.ui(16, weight: .semibold))
    }
    static var caption: AppTextStyle {
        .init(font: AppFont.ui(13))
    }
    static var buttonLabel: AppTextStyle {
        .init(font: AppFont.display(18, weight: .semibold), tracking: 1, textCase: .uppercase)
    }

    // Sinematik katman ve Film Arşivi stilleri (§08, §04 §4.4)

    static var leaderNumber: AppTextStyle {
        .init(font: AppFont.display(150, weight: .bold))
    }
    static var clapperField: AppTextStyle {
        .init(font: AppFont.display(16, weight: .semibold), textCase: .uppercase)
    }
    static var clapperLabel: AppTextStyle {
        .init(font: AppFont.ui(8.5, weight: .bold), tracking: 1, textCase: .uppercase)
    }
    static var creditsRole: AppTextStyle {
        .init(font: AppFont.ui(9.5, weight: .bold), tracking: 4, textCase: .uppercase)
    }
    static var creditsName: AppTextStyle {
        .init(font: AppFont.accent(25, weight: .black))
    }
    static var reelLabel: AppTextStyle {
        .init(font: AppFont.display(9, weight: .semibold), tracking: 1, textCase: .uppercase)
    }
    static var subtitleWord: AppTextStyle {
        .init(font: AppFont.display(34, weight: .bold), tracking: 1, textCase: .uppercase)
    }
}

extension View {
    func textStyle(_ style: AppTextStyle) -> some View {
        self.font(style.font)
            .tracking(style.tracking)
            .textCase(style.textCase)
    }
}

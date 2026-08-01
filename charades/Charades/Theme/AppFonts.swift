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

    /// §2'nin geniş harf aralığı ayrık yazılan alfabeler için. Arapça bitişik
    /// yazılıyor: harflerin arasına boşluk girince bağlar kopuyor ve
    /// `مجموعاتي` ekranda `مجمو عا تي` gibi üç parçaya bölünmüş görünüyor.
    static var appliesTracking: Bool { currentLanguageCode() != "ar" }

    // MARK: Roller

    /// §7 "gövde metinleri ölçeklenir": `scales` dolu olan her çağrı Dynamic
    /// Type ile büyüyor, `nil` olan sabit puntoda kalıyor.
    ///
    /// Varsayılanlar rollerin işine göre: `ui` gövde metni yazıyor, ölçeklenmesi
    /// beklenen varsayılan davranış. `display` ve `accent` ise sayaç, oyun
    /// kelimesi, jenerik gibi **sabit geometrili** yüzeylerde kullanılıyor;
    /// oralarda punto düzenin bir parçası, ölçeklenirse kutuyu taşırıyor. O iki
    /// rolde ölçekleme, gerçekten gövde olan token'larda tek tek açılıyor
    /// (`screenTitle`, `posterTitle`, `buttonLabel`).
    static func display(
        _ size: CGFloat,
        weight: Font.Weight = .bold,
        scales: Font.TextStyle? = nil
    ) -> Font {
        resolve(role: .display, size: size, weight: weight, italic: false, scales: scales)
    }

    static func accent(
        _ size: CGFloat,
        weight: Font.Weight = .black,
        italic: Bool = false,
        scales: Font.TextStyle? = nil
    ) -> Font {
        resolve(role: .accent, size: size, weight: weight, italic: italic, scales: scales)
    }

    static func ui(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        scales: Font.TextStyle? = .body
    ) -> Font {
        resolve(role: .ui, size: size, weight: weight, italic: false, scales: scales)
    }

    private enum Role { case display, accent, ui }

    private static func resolve(
        role: Role,
        size: CGFloat,
        weight: Font.Weight,
        italic: Bool,
        scales: Font.TextStyle?
    ) -> Font {
        let family: String
        switch role {
        case .display: family = families.display
        case .accent: family = families.accent
        case .ui: family = families.ui
        }

        for name in postScriptCandidates(family: family, weight: weight, italic: italic) {
            if UIFont(name: name, size: size) != nil {
                // `Font.custom(_:size:)` sessizce gövdeye göre ölçekleniyor;
                // sabit punto istemenin tek yolu `fixedSize:`. Bu ayrım
                // gözden kaçınca oyun kartı ve logo da büyüyordu.
                guard let scales else { return .custom(name, fixedSize: size) }
                return .custom(name, size: size, relativeTo: scales)
            }
        }

        if let base = UIFont(name: family, size: size) {
            var traits: UIFontDescriptor.SymbolicTraits = []
            if weight.rank >= Font.Weight.semibold.rank { traits.insert(.traitBold) }
            if italic { traits.insert(.traitItalic) }
            let resolved = traits.isEmpty
                ? base
                : base.fontDescriptor.withSymbolicTraits(traits).map { UIFont(descriptor: $0, size: size) } ?? base
            return Font(scaled(resolved, to: scales))
        }

        guard let scales else {
            return .system(size: size, weight: weight, design: role == .accent ? .serif : .default)
        }
        return .system(scales, design: role == .accent ? .serif : .default, weight: weight)
    }

    /// `Font.custom(_:size:relativeTo:)`ın `UIFont` karşılığı; ikame yolunda da
    /// aynı ölçekleme geçerli olsun diye.
    private static func scaled(_ font: UIFont, to scales: Font.TextStyle?) -> UIFont {
        guard let scales else { return font }
        return UIFontMetrics(forTextStyle: scales.uiTextStyle).scaledFont(for: font)
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

private extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        default: return .body
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
    /// Ölçeklenmiyor: bu bir metin değil **kelime markası**. Büyüdüğünde header
    /// bandını kırıyor ve zaten bir bilgi taşımıyor — altındaki ekran başlıkları
    /// ve gövde metinleri ölçekleniyor (§7).
    static var marquee: AppTextStyle {
        .init(font: AppFont.display(44, weight: .bold), tracking: 2, textCase: .uppercase)
    }
    static var screenTitle: AppTextStyle {
        .init(font: AppFont.display(28, weight: .bold, scales: .title), tracking: 1.5, textCase: .uppercase)
    }
    static var posterTitle: AppTextStyle {
        .init(font: AppFont.accent(22, weight: .black, scales: .title3))
    }
    /// §7: `gameWord` kendi dinamik küçültme mantığını kullanıyor — punto zaten
    /// moda ve yöne göre hesaplanıyor, üstüne Dynamic Type binince kelime
    /// kartın dışına taşıyor.
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
        .init(font: AppFont.display(18, weight: .semibold, scales: .headline), tracking: 1, textCase: .uppercase)
    }

    // Sinematik katman ve Film Arşivi stilleri (§08, §04 §4.4).
    // Hiçbiri ölçeklenmiyor: hepsi sabit geometrili yüzeylerde (klaket künyesi,
    // jenerik akışı, geri sayım rakamı, replay altyazısı) duruyor.

    static var leaderNumber: AppTextStyle {
        .init(font: AppFont.display(150, weight: .bold))
    }
    static var clapperField: AppTextStyle {
        .init(font: AppFont.display(16, weight: .semibold), textCase: .uppercase)
    }
    static var clapperLabel: AppTextStyle {
        .init(font: AppFont.ui(8.5, weight: .bold, scales: nil), tracking: 1, textCase: .uppercase)
    }
    static var creditsRole: AppTextStyle {
        .init(font: AppFont.ui(9.5, weight: .bold, scales: nil), tracking: 4, textCase: .uppercase)
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
            .appTracking(style.tracking)
            .textCase(style.textCase)
    }

    /// Harf aralığını locale'e göre uygular. Çağrı yerlerinde `.tracking(_:)`
    /// yerine bu kullanılıyor; koşul tek yerde duruyor (§2).
    func appTracking(_ value: CGFloat) -> some View {
        tracking(AppFont.appliesTracking ? value : 0)
    }
}

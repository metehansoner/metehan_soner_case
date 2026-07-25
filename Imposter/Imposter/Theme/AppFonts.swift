import SwiftUI
import UIKit

enum AppFont {
    enum Family {
        static let display = "Fredoka"
        static let ui = "Nunito"
    }

    /// Chunky titles / brand / settings chrome (Fakeit-style Fredoka Bold).
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        custom(Family.display, size: size, weight: weight)
            ?? .system(size: size, weight: weight, design: .rounded)
    }

    /// Body / supporting UI copy.
    static func ui(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        custom(Family.ui, size: size, weight: weight)
            ?? .system(size: size, weight: weight, design: .rounded)
    }

    private static func custom(_ family: String, size: CGFloat, weight: Font.Weight) -> Font? {
        let candidates = postScriptCandidates(family: family, weight: weight)
        for name in candidates {
            if UIFont(name: name, size: size) != nil {
                return .custom(name, size: size)
            }
        }
        // Family + traits fallback
        if let font = UIFont(name: family, size: size) {
            let traits = uiFontTraits(for: weight)
            if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                return Font(UIFont(descriptor: descriptor, size: size))
            }
            return Font(font)
        }
        return nil
    }

    private static func postScriptCandidates(family: String, weight: Font.Weight) -> [String] {
        switch (family, weight) {
        case (Family.display, .bold), (Family.display, .heavy), (Family.display, .black):
            return ["Fredoka-Bold", "FredokaBold"]
        case (Family.display, .semibold), (Family.display, .medium):
            return ["Fredoka-SemiBold", "FredokaSemiBold", "Fredoka-Bold"]
        case (Family.display, _):
            return ["Fredoka-Regular", "FredokaRegular", "Fredoka-SemiBold"]

        case (Family.ui, .black), (Family.ui, .heavy):
            return ["Nunito-ExtraBold", "NunitoExtraBold", "Nunito-Bold", "NunitoBold"]
        case (Family.ui, .bold):
            return ["Nunito-Bold", "NunitoBold", "Nunito-ExtraBold"]
        case (Family.ui, .semibold), (Family.ui, .medium):
            return ["Nunito-SemiBold", "NunitoSemiBold", "Nunito-Bold"]
        default:
            return ["Nunito-Regular", "NunitoRegular", "Nunito-SemiBold"]
        }
    }

    private static func uiFontTraits(for weight: Font.Weight) -> UIFontDescriptor.SymbolicTraits {
        switch weight {
        case .bold, .heavy, .black, .semibold:
            return .traitBold
        default:
            return []
        }
    }
}

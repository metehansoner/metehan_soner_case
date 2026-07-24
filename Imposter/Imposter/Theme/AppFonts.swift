import SwiftUI
import UIKit

enum AppFont {
    enum Family {
        static let display = "Fredoka"
        static let ui = "Nunito"
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        custom(Family.display, size: size, weight: weight)
            ?? .system(size: size, weight: weight, design: .rounded)
    }

    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        custom(Family.ui, size: size, weight: weight)
            ?? .system(size: size, weight: weight, design: .rounded)
    }

    private static func custom(_ family: String, size: CGFloat, weight: Font.Weight) -> Font? {
        let name: String
        switch (family, weight) {
        case (Family.display, .bold), (Family.display, .heavy), (Family.display, .black):
            name = "Fredoka-Bold"
        case (Family.display, .semibold), (Family.display, .medium):
            name = "Fredoka-SemiBold"
        case (Family.display, _):
            name = "Fredoka-Regular"
        case (Family.ui, .bold), (Family.ui, .heavy), (Family.ui, .black):
            name = "Nunito-Bold"
        case (Family.ui, .semibold), (Family.ui, .medium):
            name = "Nunito-SemiBold"
        default:
            name = "Nunito-Regular"
        }
        // PostScript names can vary; try both hyphenated and spaced.
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        let alt = name.replacingOccurrences(of: "-", with: "")
        if UIFont(name: alt, size: size) != nil {
            return .custom(alt, size: size)
        }
        return nil
    }
}

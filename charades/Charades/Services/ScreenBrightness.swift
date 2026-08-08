import UIKit


@MainActor
enum ScreenBrightness {

    private static let dimLevel: CGFloat = 0.25

    private static var savedLevel: CGFloat?

    static func dim() {
        guard savedLevel == nil else { return }
        let current = UIScreen.main.brightness

        guard current > dimLevel else { return }
        savedLevel = current
        UIScreen.main.brightness = dimLevel
    }

    static func restore() {
        guard let savedLevel else { return }
        UIScreen.main.brightness = savedLevel
        self.savedLevel = nil
    }
}

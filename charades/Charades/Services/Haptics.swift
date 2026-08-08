import UIKit


@MainActor
enum Haptics {


    static func primaryButton() { impact(.medium) }


    static func secondaryButton() { impact(.light) }


    static func deckSelected() { impact(.rigid) }


    static func deckDeselected() { impact(.soft) }


    static func modeSelected() { impact(.rigid) }


    static func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }


    static func stepperLimit() { impact(.soft, intensity: 0.4) }

    static func switchOn() { impact(.rigid, intensity: 0.8) }
    static func switchOff() { impact(.soft, intensity: 0.6) }


    static func lockedWall() { impact(.rigid, intensity: 0.6) }


    static func answerCorrect() { notify(.success) }
    static func answerSkip() { notify(.warning) }


    static func countdownTick() { impact(.medium) }


    static func warningTick() { impact(.light, intensity: 0.4) }

    static func timeUp() { impact(.heavy) }


    static func clapper() { impact(.heavy) }


    static func purchaseSucceeded() { notify(.success) }


    static func exportSucceeded() { notify(.success) }
    static func purchaseFailed() { notify(.error) }
    static func matchWon() { notify(.success) }


    static func prepareImpact() {
        guard isEnabled else { return }
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
    }

    static func prepareNotification() {
        guard isEnabled else { return }
        notificationGenerator.prepare()
    }


    private static var isEnabled: Bool { AppSettingsStore.shared.hapticsEnabled }

    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private static let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    private static func generator(
        for style: UIImpactFeedbackGenerator.FeedbackStyle
    ) -> UIImpactFeedbackGenerator {
        switch style {
        case .light: lightGenerator
        case .medium: mediumGenerator
        case .heavy: heavyGenerator
        case .rigid: rigidGenerator
        case .soft: softGenerator
        @unknown default: mediumGenerator
        }
    }

    private static func impact(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle,
        intensity: CGFloat = 1
    ) {
        guard isEnabled else { return }
        let generator = generator(for: style)
        generator.impactOccurred(intensity: intensity)


        generator.prepare()
    }

    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(type)
        notificationGenerator.prepare()
    }
}

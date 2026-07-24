import UIKit

enum Haptics {
    static func light() {
        guard AppSettingsStore.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard AppSettingsStore.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        guard AppSettingsStore.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        guard AppSettingsStore.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard AppSettingsStore.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        guard AppSettingsStore.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func selection() {
        guard AppSettingsStore.shared.hapticsEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

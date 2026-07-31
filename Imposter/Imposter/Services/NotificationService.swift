import Foundation
import UserNotifications
import UIKit

enum NotificationToggleResult {
    case done
    case openSystemSettings
}

@MainActor
enum NotificationService {
    static let dailyIdentifier = "imposter.daily.evening"

    private static let eveningHour = 20
    private static let eveningMinute = 0

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func isAuthorized() async -> Bool {
        let status = await authorizationStatus()
        return status == .authorized || status == .provisional || status == .ephemeral
    }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            let settings = AppSettingsStore.shared
            settings.notificationPermissionPrompted = true
            if granted {
                settings.notificationsEnabled = true
                await refreshSchedule()
            } else {
                settings.notificationsEnabled = false
                cancelAll()
            }
            return granted
        } catch {
            let settings = AppSettingsStore.shared
            settings.notificationPermissionPrompted = true
            settings.notificationsEnabled = false
            cancelAll()
            return false
        }
    }

    static func refreshSchedule() async {
        let settings = AppSettingsStore.shared
        guard settings.notificationsEnabled, await isAuthorized() else {
            cancelAll()
            return
        }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyIdentifier])

        let content = UNMutableNotificationContent()
        let copy = dailyCopy()
        content.title = copy.title
        content.body = copy.body
        content.sound = .default

        var date = DateComponents()
        date.hour = eveningHour
        date.minute = eveningMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(
            identifier: dailyIdentifier,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [dailyIdentifier])
    }

    static func openAppNotificationSettings() {
        let notificationURL = URL(string: UIApplication.openNotificationSettingsURLString)
        let appSettingsURL = URL(string: UIApplication.openSettingsURLString)

        if let notificationURL {
            UIApplication.shared.open(notificationURL, options: [:]) { opened in
                guard !opened, let appSettingsURL else { return }
                UIApplication.shared.open(appSettingsURL, options: [:], completionHandler: nil)
            }
            return
        }

        if let appSettingsURL {
            UIApplication.shared.open(appSettingsURL, options: [:], completionHandler: nil)
        }
    }

    @discardableResult
    static func handleToggle(enabled: Bool) async -> NotificationToggleResult {
        let settings = AppSettingsStore.shared

        guard enabled else {
            settings.notificationsEnabled = false
            settings.awaitingSystemNotificationEnable = false
            cancelAll()
            return .done
        }

        let status = await authorizationStatus()
        switch status {
        case .notDetermined:
            let granted = await requestAuthorization()
            if granted { return .done }
            settings.notificationsEnabled = false
            if await authorizationStatus() == .denied {
                settings.awaitingSystemNotificationEnable = true
                return .openSystemSettings
            }
            return .done
        case .authorized, .provisional, .ephemeral:
            settings.notificationsEnabled = true
            settings.awaitingSystemNotificationEnable = false
            await refreshSchedule()
            return .done
        case .denied:
            settings.notificationsEnabled = false
            settings.awaitingSystemNotificationEnable = true
            return .openSystemSettings
        @unknown default:
            settings.notificationsEnabled = false
            settings.awaitingSystemNotificationEnable = true
            return .openSystemSettings
        }
    }

    static func syncPreferenceWithSystem(isReturningToForeground: Bool = false) async {
        let settings = AppSettingsStore.shared
        let authorized = await isAuthorized()

        if settings.awaitingSystemNotificationEnable {
            guard isReturningToForeground else { return }
            settings.awaitingSystemNotificationEnable = false
            if authorized {
                settings.notificationsEnabled = true
                await refreshSchedule()
            } else {
                settings.notificationsEnabled = false
                cancelAll()
            }
            return
        }

        if !authorized {
            settings.notificationsEnabled = false
            cancelAll()
            return
        }

        if settings.notificationsEnabled {
            await refreshSchedule()
        } else {
            cancelAll()
        }
    }

    private static func dailyCopy() -> (title: String, body: String) {
        let l10n = LocalizationManager.shared
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = ((day - 1) % 6) + 1
        return (
            l10n.t("notification.daily.\(index).title"),
            l10n.t("notification.daily.\(index).body")
        )
    }
}

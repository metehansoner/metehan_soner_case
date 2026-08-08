import UserNotifications


enum NotificationService {
    private static let dailyFreeDeckPrefix = "dailyFreeDeck."
    private static let engagementPrefix = "engage."
    private static let trialEndingID = "trialEnding"


    private static let scheduleWindowDays = 14


    private static let eveningHour = 18

    private static let lateHour = 20

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func isAuthorized() async -> Bool {
        switch await authorizationStatus() {
        case .authorized, .provisional, .ephemeral: true
        default: false
        }
    }


    @discardableResult
    static func requestAuthorization() async -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: options)) ?? false
        scheduleChanged()
        return granted
    }


    private static var scheduling: Task<Void, Never>?


    static func scheduleChanged() {
        let previous = scheduling
        scheduling = Task {
            await previous?.value
            await refreshSchedule()
        }
    }

    static func refreshSchedule() async {
        let center = UNUserNotificationCenter.current()
        await clearPrefixedRequests(in: center, prefix: dailyFreeDeckPrefix)
        await clearPrefixedRequests(in: center, prefix: engagementPrefix)

        guard await isAuthorized() else { return }
        let (isEnabled, wantsDailyDeck, isPremium) = await MainActor.run {
            let settings = AppSettingsStore.shared
            return (
                settings.notificationsEnabled,
                settings.dailyFreeDeckNotice,
                SubscriptionStore.shared.isPremium
            )
        }
        guard isEnabled else { return }

        let schedulesDailyFree = wantsDailyDeck && !isPremium

        await enqueueLocalNotifications(
            center: center,
            schedulesDailyFree: schedulesDailyFree
        )

        #if DEBUG
        let pending = await center.pendingNotificationRequests()
        print("[bildirim] \(pending.count) bekleyen — \(pending.first?.content.body ?? "—")")
        #endif
    }


    static func scheduleTrialEndingNotice(trialEndsAt: Date) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [trialEndingID])

        guard await isAuthorized() else { return }
        let fireDate = trialEndsAt.addingTimeInterval(-24 * 60 * 60)
        guard fireDate > .now else { return }

        let text = await MainActor.run {
            let l10n = LocalizationManager.shared
            return (
                title: l10n.t("notification.trialEnding.title"),
                body: l10n.t("notification.trialEnding.body")
            )
        }

        let content = UNMutableNotificationContent()
        content.title = text.title
        content.body = text.body
        content.sound = .default

        let interval = fireDate.timeIntervalSinceNow
        let request = UNNotificationRequest(
            identifier: trialEndingID,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        )
        try? await center.add(request)
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }


    private static func clearPrefixedRequests(
        in center: UNUserNotificationCenter,
        prefix: String
    ) async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }


    @MainActor
    private static func enqueueLocalNotifications(
        center: UNUserNotificationCenter,
        schedulesDailyFree: Bool
    ) async {
        if schedulesDailyFree {
            for request in dailyFreeDeckRequests() {
                try? await center.add(request)
            }
        }


        for request in engagementRequests(skipEveningHour: schedulesDailyFree) {
            try? await center.add(request)
        }
    }


    @MainActor
    private static func dailyFreeDeckRequests() -> [UNNotificationRequest] {
        let l10n = LocalizationManager.shared
        let calendar = Calendar.current
        let title = l10n.t("notification.dailyFreeDeck.title")

        return (0..<scheduleWindowDays).compactMap { offset in
            guard
                let day = calendar.date(byAdding: .day, value: offset, to: .now),
                var components = calendar.dateComponents([.year, .month, .day], from: day) as DateComponents?,
                let deckID = DeckCatalog.dailyFreeDeckID(on: day, calendar: calendar, ignoringPin: true)
            else { return nil }

            components.hour = eveningHour
            components.minute = 0
            guard let fireDate = calendar.date(from: components), fireDate > .now else { return nil }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = l10n.t(
                "notification.dailyFreeDeck.body",
                ["deck": l10n.t(DeckCatalog.deck(deckID)?.titleKey ?? deckID)]
            )
            content.sound = .default

            return UNNotificationRequest(
                identifier: "\(dailyFreeDeckPrefix)\(offset)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
        }
    }


    @MainActor
    private static func engagementRequests(skipEveningHour: Bool) -> [UNNotificationRequest] {
        let l10n = LocalizationManager.shared
        let calendar = Calendar.current
        let hours = skipEveningHour ? [lateHour] : [eveningHour, lateHour]

        return (0..<scheduleWindowDays).flatMap { offset -> [UNNotificationRequest] in
            guard let day = calendar.date(byAdding: .day, value: offset, to: .now) else { return [] }

            return hours.compactMap { hour in
                var components = calendar.dateComponents([.year, .month, .day], from: day)
                components.hour = hour
                components.minute = 0
                guard let fireDate = calendar.date(from: components), fireDate > .now else { return nil }

                let copy = engagementCopy(day: day, hour: hour, l10n: l10n)
                let content = UNMutableNotificationContent()
                content.title = copy.title
                content.body = copy.body
                content.sound = .default

                return UNNotificationRequest(
                    identifier: "\(engagementPrefix)\(hour).\(offset)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                )
            }
        }
    }


    @MainActor
    private static func engagementCopy(
        day: Date,
        hour: Int,
        l10n: LocalizationManager
    ) -> (title: String, body: String) {
        let dayNumber = Calendar.current.ordinality(of: .day, in: .era, for: day) ?? 0

        let mix = dayNumber &* 2654435761 &+ hour &* 40503
        let variants = ["a", "b", "c", "d"]
        let key = variants[abs(mix) % variants.count]
        return (
            title: l10n.t("notification.engage.\(key).title"),
            body: l10n.t("notification.engage.\(key).body")
        )
    }
}

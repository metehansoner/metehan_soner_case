import UserNotifications

/// Bildirimler — 06-ayarlar-ve-lokalizasyon.md §1 "Grup 3" ve "Ne gönderiyoruz".
///
/// Hepsi **yerel**. Sunucu yok: APNs / Firebase Messaging yok (§ `07` §4).
/// Saat `Calendar.current` ile cihazın **yerel saat diliminde** planlanır —
/// Türkiye'de 18:00 ise ABD'de de o cihazın 18:00'inde düşer.
///
/// Metin planlama anında `LocalizationManager` dilinden yazılır; dil değişince
/// `scheduleChanged()` tüm kuyruğu yeniden kurar.
enum NotificationService {
    private static let dailyFreeDeckPrefix = "dailyFreeDeck."
    private static let engagementPrefix = "engage."
    private static let trialEndingID = "trialEnding"

    /// § `06` §3: metinde **o günün** deste adı geçtiği için tekrarlayan tetik
    /// kullanılamıyor. Onun yerine iki haftalık pencere tek tek planlanıyor.
    private static let scheduleWindowDays = 14

    /// Akşam parti saati — günlük bedava deste + engagement.
    private static let eveningHour = 18
    /// İkinci hatırlatma: kullanıcıyı uygulamaya çekmek.
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

    /// Sistem diyaloğunu açıyor. Hata durumunda `false`: izin verilmemiş sayılıyor,
    /// uygulama akışı değişmiyor.
    @discardableResult
    static func requestAuthorization() async -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: options)) ?? false
        scheduleChanged()
        return granted
    }

    /// Açılışta dil, abonelik ve tercih art arda tetikleyebiliyor; iki planlama
    /// iç içe girerse biri diğerinin eklediğini siliyor.
    private static var scheduling: Task<Void, Never>?

    /// Planlamayı etkileyen bir şey değişti: dil, abonelik, bildirim tercihi ya
    /// da izin. Planlanan metin planlama anında sabitlendiği için dil değişince
    /// hepsi yeniden yazılmalı.
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
        if schedulesDailyFree {
            for request in await MainActor.run({ dailyFreeDeckRequests() }) {
                try? await center.add(request)
            }
        }

        // 18:00'de bedava deste zaten varsa engagement'ı o saate koyma —
        // aynı anda iki bildirim düşmesin. 20:00 herkese engagement.
        for request in await MainActor.run({
            engagementRequests(skipEveningHour: schedulesDailyFree)
        }) {
            try? await center.add(request)
        }

        #if DEBUG
        let pending = await center.pendingNotificationRequests()
        print("[bildirim] \(pending.count) bekleyen — \(pending.first?.content.body ?? "—")")
        #endif
    }

    /// § `09` §7: sessiz kesinti şikâyet üretiyor. Deneme bitiminden 24 saat önce,
    /// tek seferlik.
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

    // MARK: - Temizlik

    private static func clearPrefixedRequests(
        in center: UNUserNotificationCenter,
        prefix: String
    ) async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Günlük bedava deste (18:00 yerel)

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

    // MARK: - Engagement (yerel 18:00 / 20:00)

    /// Uygulamaya çekme hatırlatmaları. Metin güne ve saate göre döner; dil
    /// uygulama dilidir (cihaz dili değil).
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

    /// Gün + saat için kararlı “zar”: yeniden planlamada aynı güne aynı metin
    /// düşer; ertesi gün havuzdaki dört metinden başka biri gelir.
    @MainActor
    private static func engagementCopy(
        day: Date,
        hour: Int,
        l10n: LocalizationManager
    ) -> (title: String, body: String) {
        let dayNumber = Calendar.current.ordinality(of: .day, in: .era, for: day) ?? 0
        // Basit karıştırma — a/b/c/d eşit şansla, gün gün değişir.
        let mix = dayNumber &* 2654435761 &+ hour &* 40503
        let variants = ["a", "b", "c", "d"]
        let key = variants[abs(mix) % variants.count]
        return (
            title: l10n.t("notification.engage.\(key).title"),
            body: l10n.t("notification.engage.\(key).body")
        )
    }
}

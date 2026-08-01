import UserNotifications

/// Bildirimler — 06-ayarlar-ve-lokalizasyon.md §1 "Grup 3" ve "Ne gönderiyoruz".
///
/// İki bildirim, ikisi de **yerel**. Sunucu yok: APNs, push sertifikası,
/// `aps-environment` entitlement'ı ve Firebase Messaging hiç girmiyor (§ `07` §4).
///
/// `.provisional` bilinçli olarak kullanılmıyor: sessizce Bildirim Merkezi'ne
/// düşen "bugün bedava" hiçbir işe yaramıyor, değerinin tamamı zamanında
/// görülmesinde.
///
/// Ayrım § `06` §3'ün kendi cümlesi: **izin iOS'un, içerik bizim.** Burada izin
/// durumu okunuyor ve kullanıcının tercihi + izin birlikte doğruysa planlama
/// yapılıyor; iki kaynak asla kopyalanmıyor.
enum NotificationService {
    private static let dailyFreeDeckPrefix = "dailyFreeDeck."
    private static let trialEndingID = "trialEnding"

    /// § `06` §3: metinde **o günün** deste adı geçtiği için tekrarlayan tetik
    /// kullanılamıyor — `UNCalendarNotificationTrigger(repeats: true)` tek bir
    /// sabit metin taşıyor. Onun yerine iki haftalık pencere tek tek planlanıyor.
    /// 64 bekleyen bildirim sınırının çok altında kalıyoruz.
    private static let scheduleWindowDays = 14

    /// § `06` §3: akşam açılan bir parti oyunu. Sabah gönderilen "bugün bedava"
    /// akşama kadar unutuluyor.
    private static let dailyFreeDeckHour = 18

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
    /// da izin. § `06` §3'teki ikinci tuzak burada kapanıyor — planlanan metin
    /// planlama anında sabitlendiği için dil değişince hepsi yeniden yazılmalı.
    static func scheduleChanged() {
        let previous = scheduling
        scheduling = Task {
            await previous?.value
            await refreshSchedule()
        }
    }

    static func refreshSchedule() async {
        let center = UNUserNotificationCenter.current()
        await clearDailyFreeDeckRequests(in: center)

        guard await isAuthorized() else { return }
        let (isEnabled, wantsDailyDeck, isPremium) = await MainActor.run {
            let settings = AppSettingsStore.shared
            return (
                settings.notificationsEnabled,
                settings.dailyFreeDeckNotice,
                SubscriptionStore.shared.isPremium
            )
        }
        // Premium kullanıcıya "bugün bedava" anlamsız: her deste zaten açık.
        guard isEnabled, wantsDailyDeck, !isPremium else { return }

        for request in dailyFreeDeckRequests() {
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

    // MARK: - Günlük bedava deste

    private static func clearDailyFreeDeckRequests(in center: UNUserNotificationCenter) async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(dailyFreeDeckPrefix) }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
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

            components.hour = dailyFreeDeckHour
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
}

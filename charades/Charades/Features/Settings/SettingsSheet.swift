import AVFoundation
import StoreKit
import SwiftUI
import UserNotifications


struct SettingsSheet: View {
    var onManageSubscription: () -> Void


    var onUpgrade: () -> Void


    var onOpenArchive: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppSettingsStore.self) private var settings
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase

    @State private var isShowingLanguage = false
    @State private var isShowingHowToPlay = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var cameraStatus = ReplayRecorder.cameraAuthorization
    @State private var isShowingReplayPrivacy = false
    @State private var restoreResult: String?
    @State private var didCopyUserID = false
    @State private var archiveStats: (count: Int, bytes: Int64) = (0, 0)

    var body: some View {
        SheetScaffold(title: l10n.t("settings.title")) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    playGroup
                    feelGroup
                    notificationsGroup
                    accountGroup
                    supportGroup
                    identityCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $isShowingLanguage) {
            LanguageSheet { isShowingLanguage = false }
                .environment(l10n)
        }
        .sheet(isPresented: $isShowingHowToPlay) {
            HowToPlaySlider(
                mode: .classic,
                startsRound: false,
                onClose: { isShowingHowToPlay = false },
                onFinish: { isShowingHowToPlay = false }
            )
            .environment(l10n)
            .environment(settings)
            .presentationDetents([.large])
        }
        .sheet(isPresented: $isShowingReplayPrivacy) {
            ReplayPrivacySheet(
                onContinue: requestCameraAccess,
                onCancel: { isShowingReplayPrivacy = false }
            )
            .environment(l10n)
        }
        .task { await readNotificationStatus() }
        .task { archiveStats = (ReplayStore.reelCount(), ReplayStore.totalBytes()) }


        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            cameraStatus = ReplayRecorder.cameraAuthorization
            syncReplaySwitch()
            Task { await readNotificationStatus() }
        }
    }


    private var playGroup: some View {
        @Bindable var settings = settings

        return SettingsGroup(title: l10n.t("settings.group.play")) {


            SettingsRow(
                icon: "globe",
                title: l10n.t("settings.language"),
                action: { isShowingLanguage = true }
            ) {
                SettingsDisclosure(value: LocalizationManager.languageDisplayName(l10n.localeCode))
            }

            SettingsDivider()

            SettingsRow(icon: "timer", title: l10n.t("settings.roundDuration")) {
                SettingsStepper(
                    value: $settings.roundDuration,
                    range: GameMode.durationRange,
                    step: GameMode.durationStep,
                    format: { l10n.t("preset.seconds", ["count": "\($0)"]) }
                )
            }

            SettingsDivider()

            SettingsRow(
                icon: "hand.tap",
                title: l10n.t("settings.answerMethod"),
                placement: .below
            ) {
                SettingsSegment(
                    options: [false, true],
                    title: { l10n.t($0 ? "settings.answer.tap" : "settings.answer.tilt") },
                    selection: $settings.prefersTouchAnswers
                )
            }

            SettingsDivider()

            SettingsRow(
                icon: "dial.medium",
                title: l10n.t("settings.difficulty"),
                placement: .below
            ) {
                SettingsSegment(
                    options: CardDifficultyFilter.allCases,
                    title: { l10n.t($0.titleKey) },
                    selection: $settings.difficulty
                )
            }

            SettingsDivider()

            SettingsRow(
                icon: "questionmark.circle",
                title: l10n.t("howToPlay.title"),
                action: { isShowingHowToPlay = true }
            ) {
                SettingsDisclosure()
            }
        }
    }


    private var feelGroup: some View {
        @Bindable var settings = settings

        return SettingsGroup(title: l10n.t("settings.group.feel")) {


            switchRow(icon: "iphone.radiowaves.left.and.right", key: "settings.haptics", isOn: $settings.hapticsEnabled)
            SettingsDivider()
            switchRow(icon: "speaker.wave.2", key: "settings.sound", isOn: $settings.soundEnabled)
            SettingsDivider()


            switchRow(icon: "sparkles", key: "settings.filmEffects", isOn: $settings.filmEffectsEnabled)
            SettingsDivider()
            replayRow
            SettingsDivider()
            archiveRow
        }
    }


    private var archiveRow: some View {
        SettingsRow(
            icon: "film.stack",
            title: l10n.t("settings.archive"),
            subtitle: archiveSubtitle,
            action: onOpenArchive
        ) {
            SettingsDisclosure()
        }
    }

    private var archiveSubtitle: String {
        guard archiveStats.count > 0 else { return l10n.t("settings.archive.empty") }
        return l10n.t("archive.reelCount", count: archiveStats.count)
            + " · " + ArchiveModel.sizeText(archiveStats.bytes)
    }


    private var replayRow: some View {
        SettingsRow(
            icon: "video",
            title: l10n.t("settings.replay"),
            subtitle: replaySubtitle
        ) {
            MarqueeSwitch(
                isOn: Binding(
                    get: { settings.replayEnabled },
                    set: { newValue in
                        newValue ? Haptics.switchOn() : Haptics.switchOff()
                        toggleReplay(to: newValue)
                    }
                )
            )
        }
    }

    private var replaySubtitle: String? {
        if !subscriptions.isPremium { return l10n.t("settings.replay.locked") }
        if cameraStatus == .denied || cameraStatus == .restricted {
            return l10n.t("settings.replay.denied")
        }


        if settings.replayEnabled, let limit = DeviceConditions.recordingLimit() {
            return l10n.t(limit.noticeKey)
        }
        return nil
    }


    private var notificationsGroup: some View {
        @Bindable var settings = settings

        return SettingsGroup(title: l10n.t("settings.group.notifications")) {


            SettingsRow(
                icon: "bell",
                title: l10n.t("settings.notifications"),
                subtitle: notificationStatus == .denied ? l10n.t("settings.notifications.denied") : nil
            ) {
                MarqueeSwitch(
                    isOn: Binding(
                        get: { notificationsOn },
                        set: { newValue in
                            newValue ? Haptics.switchOn() : Haptics.switchOff()
                            toggleNotifications(to: newValue)
                        }
                    )
                )
                .opacity(notificationStatus == .denied ? 0.55 : 1)
            }


            if notificationsOn, !subscriptions.isPremium {
                SettingsDivider()
                switchRow(icon: "ticket", key: "settings.dailyFreeDeck", isOn: $settings.dailyFreeDeckNotice)
            }
        }
    }

    private var notificationsOn: Bool {
        notificationStatus == .authorized && settings.notificationsEnabled
    }


    private var accountGroup: some View {
        VStack(alignment: .leading, spacing: 12) {
            if subscriptions.isPremium {
                SubscriptionCard(renewalDate: subscriptions.renewalDate)
            }

            SettingsGroup(title: l10n.t("settings.group.account")) {
                SettingsRow(
                    icon: "creditcard",
                    title: l10n.t("settings.manageSubscription"),
                    action: onManageSubscription
                ) {
                    SettingsDisclosure()
                }

                SettingsDivider()

                SettingsRow(
                    icon: "arrow.clockwise",
                    title: l10n.t("settings.restore"),
                    subtitle: restoreResult,
                    action: restore,
                    isEnabled: !subscriptions.isRestoring
                ) {
                    if subscriptions.isRestoring {
                        ProgressView().tint(AppColors.accentGold)
                    }
                }
            }
        }
    }


    private var supportGroup: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsGroup(title: l10n.t("settings.group.legal")) {
                if let mail = AppInfo.supportMailURL(
                    subject: l10n.t("settings.contact.subject"),
                    userID: settings.userID,
                    locale: l10n.localeCode
                ) {
                    SettingsRow(
                        icon: "envelope",
                        title: l10n.t("settings.contact"),
                        action: { UIApplication.shared.open(mail) }
                    ) {
                        SettingsDisclosure()
                    }

                    SettingsDivider()
                }

                SettingsRow(
                    icon: "star",
                    title: l10n.t("settings.rateUs"),


                    action: { requestReview() }
                ) {
                    SettingsDisclosure()
                }
            }

            legalLinks
        }
    }

    @ViewBuilder
    private var legalLinks: some View {

        if LegalLinks.privacy != nil || LegalLinks.terms != nil {
            HStack(spacing: 14) {
                if let privacy = LegalLinks.privacy {
                    Link(l10n.t("paywall.privacy"), destination: privacy)
                }
                if let terms = LegalLinks.terms {
                    Link(l10n.t("paywall.terms"), destination: terms)
                }
            }
            .font(AppFont.ui(11))
            .foregroundStyle(AppColors.textMuted)
            .frame(maxWidth: .infinity)
        }
    }


    private var identityCard: some View {
        VStack(spacing: 4) {
            Text(didCopyUserID ? l10n.t("settings.userID.copied") : "UserID: \(settings.userID)")
                .font(AppFont.ui(11, weight: .semibold))
                .monospaced()
                .foregroundStyle(didCopyUserID ? AppColors.accentGold : AppColors.textSecondary)

            Text(l10n.t("settings.userID.hint"))
                .font(AppFont.ui(9.5))
                .foregroundStyle(AppColors.textMuted)

            Text(l10n.t("settings.version", ["version": AppInfo.versionLine]))
                .font(AppFont.ui(9.5))
                .foregroundStyle(AppColors.textMuted)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
        .contentShape(Rectangle())
        .onLongPressGesture { copyUserID() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }


    private func switchRow(icon: String, key: String, isOn: Binding<Bool>) -> some View {
        SettingsRow(icon: icon, title: l10n.t(key)) {
            MarqueeSwitch(
                isOn: Binding(
                    get: { isOn.wrappedValue },
                    set: { newValue in
                        newValue ? Haptics.switchOn() : Haptics.switchOff()
                        isOn.wrappedValue = newValue
                    }
                )
            )
        }
    }

    private func readNotificationStatus() async {
        notificationStatus = await NotificationService.authorizationStatus()
    }


    private func toggleNotifications(to newValue: Bool) {
        switch notificationStatus {
        case .notDetermined:
            Task {
                settings.markNotificationPrompted()
                let granted = await NotificationService.requestAuthorization()
                if granted { settings.notificationsEnabled = true }
                await readNotificationStatus()
            }
        case .denied:
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        default:
            settings.notificationsEnabled = newValue
            if !newValue { NotificationService.cancelAll() }
        }
    }


    private func toggleReplay(to newValue: Bool) {
        guard newValue else {
            settings.replayEnabled = false
            return
        }
        guard subscriptions.isPremium else {
            Haptics.lockedWall()
            onUpgrade()
            return
        }

        switch cameraStatus {
        case .authorized:
            settings.replayEnabled = true
        case .denied, .restricted:
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        default:
            isShowingReplayPrivacy = true
        }
    }

    private func requestCameraAccess() {
        settings.markReplayPrivacyShown()
        Task {
            let granted = await ReplayRecorder.requestCameraAccess()
            isShowingReplayPrivacy = false
            cameraStatus = ReplayRecorder.cameraAuthorization
            settings.replayEnabled = granted
        }
    }


    private func syncReplaySwitch() {
        #if DEBUG


        if ProcessInfo.processInfo.arguments.contains("-FakeReplay") { return }
        #endif
        guard settings.replayEnabled, cameraStatus != .authorized else { return }
        settings.replayEnabled = false
    }

    private func restore() {
        Task {
            let restored = await subscriptions.restore()
            restoreResult = l10n.t(restored ? "paywall.restore.done" : "paywall.restore.none")
            restored ? Haptics.purchaseSucceeded() : Haptics.purchaseFailed()
        }
    }

    private func copyUserID() {
        UIPasteboard.general.string = settings.userID
        Haptics.selection()
        withAnimation(.easeOut(duration: 0.15)) { didCopyUserID = true }
        Task {
            try? await Task.sleep(for: .milliseconds(1500))
            withAnimation(.easeOut(duration: 0.2)) { didCopyUserID = false }
        }
    }
}

import SwiftUI
import SwiftData

@main
struct CharadesApp: App {


    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @Bindable private var l10n = LocalizationManager.shared
    private let customDeckContainer = CustomDeckStore.makeContainer()

    init() {

        AppFont.currentLanguageCode = { LocalizationManager.shared.localeCode }


        RemoteFlags.loadBundleDefaults()


        Analytics.start(userID: AppSettingsStore.shared.userID)
        RemoteFlags.fetchRemote()
        SubscriptionStore.shared.configure()


        NotificationService.scheduleChanged()


        DeckCatalog.refreshSessionOrder()


        Task { ReplayStore.runLaunchMaintenance(settings: AppSettingsStore.shared) }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(l10n)
                .environment(AppSettingsStore.shared)
                .environment(SubscriptionStore.shared)

                .environment(\.locale, Locale(identifier: l10n.localeCode))


                .environment(\.layoutDirection, l10n.layoutDirection)
                .preferredColorScheme(.dark)
        }
        .modelContainer(customDeckContainer)
    }
}

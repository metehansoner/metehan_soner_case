import SwiftUI
import SwiftData

@main
struct CharadesApp: App {
    /// §09 §1: yön kilidi `supportedInterfaceOrientationsFor` üzerinden
    /// okunuyor, o da yalnızca `UIApplicationDelegate`te var.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @Bindable private var l10n = LocalizationManager.shared
    private let customDeckContainer = CustomDeckStore.makeContainer()

    init() {
        // § `01` §2: font ailesi seçili dile bağlı ve restart'sız değişmesi gerekiyor.
        AppFont.currentLanguageCode = { LocalizationManager.shared.localeCode }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(l10n)
                .environment(AppSettingsStore.shared)
                .environment(SubscriptionStore.shared)
                // ALL CAPS dönüşümü dile duyarlı olsun diye (tr'de "i" → "İ").
                .environment(\.locale, Locale(identifier: l10n.localeCode))
                .preferredColorScheme(.dark)
        }
        .modelContainer(customDeckContainer)
    }
}

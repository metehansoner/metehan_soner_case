import SwiftUI

@main
struct CharadesApp: App {
    @Bindable private var l10n = LocalizationManager.shared

    init() {
        // § `01` §2: font ailesi seçili dile bağlı ve restart'sız değişmesi gerekiyor.
        AppFont.currentLanguageCode = { LocalizationManager.shared.localeCode }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(l10n)
                .environment(AppSettingsStore.shared)
                // ALL CAPS dönüşümü dile duyarlı olsun diye (tr'de "i" → "İ").
                .environment(\.locale, Locale(identifier: l10n.localeCode))
                .preferredColorScheme(.dark)
        }
    }
}

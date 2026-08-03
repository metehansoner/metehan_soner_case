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
        // §09 §8: RC cache'i boşken de sezon pencereleri ve rotasyon havuzu
        // doğru davransın diye bundle varsayılanları ilk iş yükleniyor.
        RemoteFlags.loadBundleDefaults()
        // §03 §5: kimlik RevenueCat ile aynı; Firebase'in `configure`ı abonelik
        // kurulumundan önce, çünkü satın alma event'leri açılışın hemen
        // ardından gelebiliyor (geri yükleme).
        Analytics.start(userID: AppSettingsStore.shared.userID)
        RemoteFlags.fetchRemote()
        SubscriptionStore.shared.configure()
        // §06 §3: bildirim metninde o günün deste adı geçtiği için tekrarlayan
        // tetik kullanılamıyor; pencere her açılışta yeniden planlanıyor.
        NotificationService.scheduleChanged()
        // All ızgarası her açılışta farklı sırada; ücretsiz kullanıcıda free
        // deste ayrıca en başa çekiliyor (`homeOrderedDecks`).
        DeckCatalog.refreshSessionOrder()
        // §04 §4.2: arşivin bakımı açılışta yapılıyor — öksüz dosyalar, yaşı
        // geçen kayıtlar ve kota. İlk kareyi beklemesin diye ertelendi.
        Task { ReplayStore.runLaunchMaintenance(settings: AppSettingsStore.shared) }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(l10n)
                .environment(AppSettingsStore.shared)
                .environment(SubscriptionStore.shared)
                // ALL CAPS dönüşümü dile duyarlı olsun diye (tr'de "i" → "İ").
                .environment(\.locale, Locale(identifier: l10n.localeCode))
                // §06 §2 RTL: dil uygulama içinden seçiliyor, sistem dilinden
                // değil; iOS'un otomatik yön çıkarımı bu yüzden devreye girmiyor.
                .environment(\.layoutDirection, l10n.layoutDirection)
                .preferredColorScheme(.dark)
        }
        .modelContainer(customDeckContainer)
    }
}

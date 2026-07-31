import SwiftUI
import FirebaseCore

@main
struct ImposterApp: App {
    init() {
        FirebaseApp.configure()
        RewardedAdService.shared.startSDK()
        SubscriptionStore.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

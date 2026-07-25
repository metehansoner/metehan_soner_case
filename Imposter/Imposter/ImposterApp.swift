import SwiftUI

@main
struct ImposterApp: App {
    init() {
        RewardedAdService.shared.startSDK()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

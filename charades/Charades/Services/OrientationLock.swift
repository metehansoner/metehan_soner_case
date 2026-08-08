import SwiftUI
import UIKit


@MainActor
@Observable
final class OrientationLock {
    static let shared = OrientationLock()


    nonisolated(unsafe) private(set) static var currentMask: UIInterfaceOrientationMask = .portrait

    private(set) var mask: UIInterfaceOrientationMask = .portrait {
        didSet { Self.currentMask = mask }
    }

    private init() {}

    func lockPortrait() { apply(.portrait) }


    func lockLandscape() { apply(.landscape) }

    private func apply(_ newMask: UIInterfaceOrientationMask) {
        guard mask != newMask else { return }
        mask = newMask

        guard
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })
        else { return }

        for window in scene.windows {
            window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: newMask)) { error in
            #if DEBUG
            print("Yön güncellemesi reddedildi: \(error)")
            #endif
        }
    }
}


final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationLock.currentMask
    }
}

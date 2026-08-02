import SwiftUI
import UIKit

/// Yön katmanı — 09-kesinti-ve-sinir-durumlari.md §1.
///
/// Uygulama penceresi **her zaman portrait**. Oyun / replay yatay düzeni
/// `ForcedLandscapeContainer` ile çiziliyor; sistem `requestGeometryUpdate`
/// ve cihaz yön kilidine bağlanılmıyor.
@MainActor
@Observable
final class OrientationLock {
    static let shared = OrientationLock()

    /// `UIApplicationDelegate` ana aktörde olmayabiliyor; maskeyi oradan
    /// okuyabilmek için `nonisolated` bir kopya tutuluyor.
    nonisolated(unsafe) private(set) static var currentMask: UIInterfaceOrientationMask = .portrait

    private(set) var mask: UIInterfaceOrientationMask = .portrait {
        didSet { Self.currentMask = mask }
    }

    private init() {}

    func lockPortrait() { apply(.portrait) }

    /// Eski sistem-landscape yolu. Oyun artık forced-landscape kullandığı için
    /// çağrılmıyor; API test / geri dönüş için duruyor.
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

/// Yön kilidinin sisteme bağlandığı tek yer. SwiftUI'ın `App`i bu delegate'i
/// `@UIApplicationDelegateAdaptor` ile alıyor.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationLock.currentMask
    }
}

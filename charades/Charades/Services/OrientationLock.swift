import SwiftUI
import UIKit

/// Yön katmanı — 09-kesinti-ve-sinir-durumlari.md §1.
///
/// Uygulamanın tamamı portrait, oyun ekranı landscape. Kilit
/// `AppDelegate.supportedInterfaceOrientationsFor` üzerinden okunuyor ve
/// `requestGeometryUpdate` ile fiili döndürme yapılıyor.
///
/// **Yön yalnızca iki kez değişiyor:** oyun girişinde landscape'e, maç sonunda
/// portrait'e. Faz başına ayrı ayrı kilit değiştirmek iOS'ta en çok görsel hata
/// üreten yer; `roundEnd` ve `paused` bu yüzden landscape kalıyor (§1 tablosu).
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

    /// §1: oyun landscape'te açılıyor. İki landscape de açık — kullanıcının
    /// telefonu hangi tarafa çevirdiği onun tercihi, tilt işareti zaten
    /// kalibrasyonda sabitleniyor (§04 §2).
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
            // Kullanıcının cihaz yön kilidi açıksa sistem isteği reddedebiliyor.
            // §1'in "yatay çeviremiyorum" yolu bu durumun kullanıcı tarafındaki
            // karşılığı; burada sessiz kalmak doğru, tur yine de oynanabiliyor.
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

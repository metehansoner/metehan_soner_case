import CoreMotion
import Foundation
import Observation
import UIKit

/// Tilt okuma katmanı — 04-oyun-modlari.md §2.
///
/// Karar mantığı `TiltDetector`da; burada yalnızca CoreMotion, kalibrasyon ve
/// **işaret sabitleme** var. Bu üçlü ayrımın sebebi işaret meselesi: alna konmuş
/// telefonda `UIDevice.current.orientation` `.faceUp`, `.portrait` ya da
/// `.unknown` dönebiliyor, hatta tur ortasında `landscapeLeft` ↔ `landscapeRight`
/// arasında salınabiliyor. İşaret tur ortasında dönerse öne eğmek PAS olur —
/// oyunun tek mekaniği tersine döner ve kullanıcı bunu "uygulama bozuk" olarak
/// yaşar. Bu yüzden işaret **kalibrasyon anında bir kez** okunup sabitleniyor.
@MainActor
@Observable
final class MotionService {
    static let shared = MotionService()

    enum State: Equatable {
        case idle
        /// Geri sayım sürüyor, baseline aranıyor.
        case calibrating
        case running
        /// Cevap animasyonu ya da duraklat: ölçüm alınıyor ama tetik üretilmiyor.
        case suspended
    }

    private(set) var state: State = .idle

    /// Kalibre edilmiş, yumuşatılmış açı (derece). Pozitif = öne = DOĞRU.
    /// Ekrandaki tilt göstergesi bunu okuyor.
    private(set) var angle: Double = 0

    /// §07 §5: sensörü olmayan/çalışmayan cihazda dokunmatik yedeğe düşülüyor.
    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    /// §09 §2: 8 saniye tetik gelmezse ekranda "Telefonu yatay tut" hatırlatması.
    private(set) var isSilentTooLong = false

    private let manager = CMMotionManager()
    private var detector = TiltDetector()
    private var calibrator = BaselineCalibrator()

    /// Kalibrasyon anında bir kez hesaplanıp tur boyunca sabit.
    private var sign: Double = 1
    private var baseline: Double = 0
    private var hasBaseline = false

    private var lastTriggerTime: TimeInterval = 0
    private var onTrigger: ((TiltDetector.Trigger) -> Void)?
    private var didPrepareForApproach = false

    private init() {}

    // MARK: Yaşam döngüsü

    /// Geri sayımda çağrılıyor: ölçüm başlar, baseline aranır, henüz tetik yok.
    func beginCalibration() {
        guard isAvailable else { return }

        detector.reset(at: now)
        calibrator.reset()
        hasBaseline = false
        baseline = 0
        angle = 0
        isSilentTooLong = false
        state = .calibrating

        guard !manager.isDeviceMotionActive else { return }

        // §2: 30 Hz yeterli, 60 Hz pil yakar.
        manager.deviceMotionUpdateInterval = 1.0 / 30
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) {
            [weak self] motion, _ in
            guard let self, let motion else { return }
            self.consume(motion)
        }
    }

    /// Geri sayım bitti: baseline kesinleşir ve tetikler açılır.
    ///
    /// §2: sabitlik sağlanamadan geri sayım biterse son ölçüm kullanılıyor ve
    /// tur içi yeniden kalibrasyon devreye giriyor. Alternatif — geri sayımı
    /// uzatmak — §08 §0'ın 3.5 saniyelik animasyon bütçesini deler.
    func startDetecting(onTrigger: @escaping (TiltDetector.Trigger) -> Void) {
        guard isAvailable else { return }

        if !hasBaseline {
            baseline = calibrator.stableBaseline ?? calibrator.fallbackBaseline ?? 0
            hasBaseline = true
        }
        self.onTrigger = onTrigger
        lastTriggerTime = now
        didPrepareForApproach = false
        detector.reset(at: now)
        state = .running
    }

    /// §2: cevap anında motion güncellemesi durur, animasyon bitince başlar.
    /// Aksi hâlde animasyon sırasında ikinci tetik geliyor.
    func suspend() {
        guard state == .running else { return }
        state = .suspended
    }

    func resume() {
        guard state == .suspended else { return }
        // Cevap animasyonu bitince telefon hâlâ eğik olabilir. Silahlı reset
        // aynı eğimde kelime yağmuru yapıyordu — nötre dönülmeden kurulmaz.
        detector.reset(at: now, rearm: false)
        state = .running
    }

    /// §09 §3: üstten aşağı sürükleme başladığı anda tetikler 600 ms kilitlenir.
    /// Telefonu alından indirme hareketi kaçınılmaz olarak 40°'yi geçiyor.
    func lockForPauseGesture() {
        detector.lockTriggers(at: now)
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        onTrigger = nil
        state = .idle
        angle = 0
        isSilentTooLong = false
    }

    // MARK: Ölçüm

    private func consume(_ motion: CMDeviceMotion) {
        let raw = Self.rollDegrees(motion)

        if state == .calibrating {
            // İşaret cihazın hangi tarafa yatırıldığına bağlı ve bunu **yer
            // çekiminden** okuyoruz: alna konmuş telefonda `gravity.x` ±1'e
            // yakın ve hangi landscape'te olduğumuzu doğrudan söylüyor.
            // `UIDevice.orientation` aynı soruya alında güvenilir cevap vermiyor.
            if abs(motion.gravity.x) > 0.5 {
                // ForcedLandscape (landscapeRight) alnında: +x → öne = DOĞRU.
                // Ters işaret öne eğince PAS üretiyordu.
                sign = motion.gravity.x > 0 ? 1 : -1
            }
            calibrator.add(raw * sign)
            angle = 0

            if let stable = calibrator.stableBaseline {
                baseline = stable
                hasBaseline = true
            }
            return
        }

        let calibrated = raw * sign - baseline

        guard state == .running else {
            // Askıdayken de ölçüm işleniyor: cevap animasyonu biterken telefon
            // nötre dönmüş olsun diye. Yalnızca tetik üretilmiyor.
            angle = calibrated
            return
        }

        if let trigger = detector.update(angle: calibrated, at: now) {
            angle = detector.smoothedAngle
            lastTriggerTime = now
            isSilentTooLong = false
            onTrigger?(trigger)
            return
        }

        angle = detector.smoothedAngle

        // §4.1: DOĞRU/PAS için generator eşiğe yaklaşırken hazırlanıyor —
        // aksi hâlde ilk haptik ~100 ms gecikiyor.
        let magnitude = abs(angle)
        if magnitude > detector.thresholds.release * 0.7,
           magnitude < detector.thresholds.arm {
            if !didPrepareForApproach {
                Haptics.prepareNotification()
                didPrepareForApproach = true
            }
        } else if magnitude < detector.thresholds.release {
            didPrepareForApproach = false
        }

        // §2: tur içi yeniden kalibrasyon — kullanıcı telefonu kaydırdığında
        // oyunun kilitlenmesini engelliyor.
        if let shift = detector.consumeBaselineShift() {
            baseline += shift
            angle = 0
        }

        // §09 §2: yön kilidi portrait'e çevirmeyi engelliyor ama kullanıcı
        // fiziksel olarak dikey tutarsa açı nötr banda düşer ve tetik gelmez.
        isSilentTooLong = now - lastTriggerTime > 8
    }

    /// Landscape'te alna konmuş telefonda anlamlı eksen `attitude.roll`:
    /// cihazın uzun ekseni yatay olduğu için öne/arkaya eğim buraya düşüyor.
    private static func rollDegrees(_ motion: CMDeviceMotion) -> Double {
        motion.attitude.roll * 180 / .pi
    }

    private var now: TimeInterval { ProcessInfo.processInfo.systemUptime }
}

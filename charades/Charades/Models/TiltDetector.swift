import Foundation

/// Tilt karar mantığı — 04-oyun-modlari.md §2.
///
/// CoreMotion'dan **bilinçli olarak bağımsız**: eşik, histerezis, cooldown ve
/// yeniden kalibrasyon kuralları oyunun tek mekaniği ve yanlış yapıldığında
/// uygulamanın tamamı bozuk hissettiriyor. Saf bir tip olduğu için cihaz
/// olmadan doğrulanabiliyor (`Scripts/tilt_check.swift`).
///
/// Açı **kalibre edilmiş** derece cinsinden geliyor: pozitif = öne (aşağı) eğim
/// = DOĞRU, negatif = arkaya eğim = PAS. İşaret düzeltmesi `MotionService`in işi.
struct TiltDetector {

    enum Trigger: Equatable {
        case correct
        case skip
    }

    /// §2 "Eşik ve durum makinesi" tablosu.
    struct Thresholds {
        /// Tetikleme eşiği.
        var arm: Double = 40
        /// Nötre dönüş eşiği. Tek eşik kullanılırsa telefon sınırda titrerken
        /// 5 kelime birden geçiyor — histerezis zorunlu.
        var release: Double = 20
        /// Tetikten sonra en az bu kadar süre yeni tetik yok. Cooldown ve
        /// "nötre dönme" koşulundan biri eksikse hatalı çift tetikleme oluyor.
        var cooldown: TimeInterval = 0.4
        /// §2: hiç tetik gelmeden bu kadar süre geçer ve açı nötr bandın
        /// dışında sabit durursa baseline sessizce güncellenir.
        var recalibrateAfter: TimeInterval = 8
        /// Yeniden kalibrasyonun "sabit duruyor" ölçütü (derece).
        var recalibrateStability: Double = 6
        /// §2: ham veri el titremesiyle gürültülü.
        var smoothingWindow = 3
    }

    var thresholds: Thresholds

    private var samples: [Double] = []
    private var isArmed = true
    private var lastTriggerTime: TimeInterval?
    private var lastTriggerOrStart: TimeInterval?
    /// Yeniden kalibrasyon penceresindeki açılar.
    private var driftSamples: [(time: TimeInterval, angle: Double)] = []
    /// §09 §3: duraklat sürüklemesi başlayınca tetikler kilitlenir.
    private var lockedUntil: TimeInterval?

    /// Yeniden kalibrasyon `MotionService`e bildirilen bir çıktı: baseline
    /// orada tutuluyor, burada yalnızca "kaydır" isteği üretiliyor.
    private(set) var pendingBaselineShift: Double?

    private(set) var smoothedAngle: Double = 0

    init(thresholds: Thresholds = Thresholds()) {
        self.thresholds = thresholds
    }

    /// §09 §3: üstten aşağı sürükleme jesti başladığı anda 600 ms kilit.
    /// Telefonu alından indirme hareketi kaçınılmaz olarak 40°'yi geçiyor;
    /// bu kilit olmadan duraklatmadan önce istemsiz bir DOĞRU/PAS kaydediliyor.
    mutating func lockTriggers(at time: TimeInterval, for duration: TimeInterval = 0.6) {
        lockedUntil = time + duration
    }

    mutating func reset(at time: TimeInterval) {
        samples.removeAll()
        driftSamples.removeAll()
        isArmed = true
        lastTriggerTime = nil
        lastTriggerOrStart = time
        lockedUntil = nil
        pendingBaselineShift = nil
        smoothedAngle = 0
    }

    mutating func consumeBaselineShift() -> Double? {
        defer { pendingBaselineShift = nil }
        return pendingBaselineShift
    }

    /// Tek ölçüm işler ve tetik üretirse döner.
    mutating func update(angle: Double, at time: TimeInterval) -> Trigger? {
        samples.append(angle)
        if samples.count > thresholds.smoothingWindow {
            samples.removeFirst(samples.count - thresholds.smoothingWindow)
        }
        let smoothed = samples.reduce(0, +) / Double(samples.count)
        smoothedAngle = smoothed

        if lastTriggerOrStart == nil { lastTriggerOrStart = time }

        // Histerezis: nötre dönmeden yeniden kurulmuyor.
        if !isArmed, abs(smoothed) < thresholds.release {
            isArmed = true
        }

        updateDrift(smoothed: smoothed, at: time)

        if let lockedUntil, time < lockedUntil { return nil }

        guard isArmed else { return nil }
        if let last = lastTriggerTime, time - last < thresholds.cooldown { return nil }
        guard abs(smoothed) > thresholds.arm else { return nil }

        isArmed = false
        lastTriggerTime = time
        lastTriggerOrStart = time
        driftSamples.removeAll()
        return smoothed > 0 ? .correct : .skip
    }

    /// §2 "Tur içi yeniden kalibrasyon": kullanıcı telefonu tur ortasında
    /// kaydırdığında oyunun kilitlenmesini engelliyor.
    private mutating func updateDrift(smoothed: Double, at time: TimeInterval) {
        guard let since = lastTriggerOrStart else { return }

        driftSamples.append((time, smoothed))
        driftSamples.removeAll { time - $0.time > thresholds.recalibrateAfter }

        guard time - since >= thresholds.recalibrateAfter else { return }
        guard abs(smoothed) >= thresholds.release else { return }

        let angles = driftSamples.map(\.angle)
        guard let minimum = angles.min(), let maximum = angles.max() else { return }
        // Sabit duruyor mu: pencere boyunca salınım küçükse kayma gerçek.
        guard maximum - minimum <= thresholds.recalibrateStability else { return }

        pendingBaselineShift = smoothed
        lastTriggerOrStart = time
        driftSamples.removeAll()
        samples.removeAll()
        smoothedAngle = 0
        isArmed = true
    }
}

/// §2 "Kalibrasyon": baseline sabitlik kontrolüyle alınır.
///
/// Önceki taslak "geri sayım biterken o anki açı" diyordu — ama geri sayımın
/// son anı tam olarak kullanıcının telefonu alnına *götürdüğü* an, yani hareket
/// hâlindeki bir açı. Yanlış baseline tüm tur boyunca kaymış eşik demek.
struct BaselineCalibrator {
    /// Son kaç ölçüme bakılıyor.
    var window = 10
    /// Pencere içindeki salınım bu derecenin altındaysa cihaz sabit sayılıyor.
    var stabilityDegrees: Double = 2.5

    private var samples: [Double] = []

    init(window: Int = 10, stabilityDegrees: Double = 2.5) {
        self.window = window
        self.stabilityDegrees = stabilityDegrees
    }

    mutating func reset() { samples.removeAll() }

    mutating func add(_ angle: Double) {
        samples.append(angle)
        if samples.count > window { samples.removeFirst(samples.count - window) }
    }

    /// Pencere dolu ve sabitse baseline döner.
    var stableBaseline: Double? {
        guard samples.count >= window,
              let minimum = samples.min(),
              let maximum = samples.max(),
              maximum - minimum <= stabilityDegrees
        else { return nil }
        return samples.reduce(0, +) / Double(samples.count)
    }

    /// §2: geri sayım bitene kadar sabitlik sağlanamazsa son ölçüm kullanılır
    /// ve tur içi yeniden kalibrasyon devreye girer.
    var fallbackBaseline: Double? { samples.last }
}

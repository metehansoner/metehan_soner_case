// Tilt karar mantığının cihazsız doğrulaması.
//
// `TiltDetector` bilerek CoreMotion'dan bağımsız yazıldı; bu dosya onu düz
// Swift olarak derleyip 04-oyun-modlari.md §2'deki kuralları senaryo senaryo
// sınıyor. Projede test hedefi yok, o yüzden doğrudan derleyici çağrılıyor:
//
//   Scripts/tilt_check.sh

import Foundation

var failures = 0
var checks = 0

func expect(_ condition: Bool, _ message: String) {
    checks += 1
    if !condition {
        failures += 1
        print("  BAŞARISIZ  \(message)")
    }
}

/// 30 Hz akış üretir; `angles` her adımda okunacak açıyı verir.
func run(
    detector: inout TiltDetector,
    seconds: Double,
    from start: Double = 0,
    angle: (Double) -> Double
) -> [(time: Double, trigger: TiltDetector.Trigger)] {
    var results: [(Double, TiltDetector.Trigger)] = []
    let step = 1.0 / 30
    var time = start
    while time < start + seconds {
        if let trigger = detector.update(angle: angle(time), at: time) {
            results.append((time, trigger))
        }
        time += step
    }
    return results
}

// MARK: 1 — Eşik ve yön

do {
    var detector = TiltDetector()
    detector.reset(at: 0)
    let triggers = run(detector: &detector, seconds: 1) { _ in 50 }
    expect(triggers.count == 1, "1a: 50° sabit eğimde tek tetik bekleniyor, \(triggers.count) geldi")
    expect(triggers.first?.trigger == .correct, "1b: öne eğim DOĞRU üretmeli")
}

do {
    var detector = TiltDetector()
    detector.reset(at: 0)
    let triggers = run(detector: &detector, seconds: 1) { _ in -50 }
    expect(triggers.first?.trigger == .skip, "1c: arkaya eğim PAS üretmeli")
}

do {
    var detector = TiltDetector()
    detector.reset(at: 0)
    let triggers = run(detector: &detector, seconds: 2) { _ in 30 }
    expect(triggers.isEmpty, "1d: 30° eşiğin (40°) altında, tetik olmamalı")
}

// MARK: 2 — Histerezis

do {
    // Eşik sınırında titreşim: 38–42° arası salınım.
    var detector = TiltDetector()
    detector.reset(at: 0)
    let triggers = run(detector: &detector, seconds: 3) { time in
        40 + 3 * sin(time * 2 * .pi * 4)
    }
    expect(
        triggers.count == 1,
        "2a: eşik sınırında titrerken tek tetik bekleniyor, \(triggers.count) geldi"
    )
}

do {
    // Nötre dönmeden ikinci kez eşiği aşmak yeni tetik üretmemeli.
    var detector = TiltDetector()
    detector.reset(at: 0)
    var triggers = run(detector: &detector, seconds: 1) { _ in 50 }
    // 25°'ye in (release 20°'nin üstünde, yani hâlâ silahsız) ve tekrar çık.
    triggers += run(detector: &detector, seconds: 1, from: 1) { _ in 25 }
    triggers += run(detector: &detector, seconds: 1, from: 2) { _ in 55 }
    expect(triggers.count == 1, "2b: nötre (<20°) dönmeden yeniden tetiklenmemeli, \(triggers.count) geldi")
}

do {
    // Nötre dönünce yeniden tetiklenebilmeli.
    var detector = TiltDetector()
    detector.reset(at: 0)
    var triggers = run(detector: &detector, seconds: 1) { _ in 50 }
    triggers += run(detector: &detector, seconds: 1, from: 1) { _ in 5 }
    triggers += run(detector: &detector, seconds: 1, from: 2) { _ in 50 }
    expect(triggers.count == 2, "2c: nötre dönüp tekrar eğilince ikinci tetik gelmeli, \(triggers.count) geldi")
}

// MARK: 3 — Cooldown

do {
    var detector = TiltDetector()
    detector.reset(at: 0)
    // 0.2 sn içinde nötre dön ve tekrar eğil — cooldown 0.4 sn.
    var triggers = run(detector: &detector, seconds: 0.2) { _ in 50 }
    triggers += run(detector: &detector, seconds: 0.1, from: 0.2) { _ in 0 }
    triggers += run(detector: &detector, seconds: 0.1, from: 0.3) { _ in 50 }
    expect(triggers.count == 1, "3a: 400 ms cooldown içinde ikinci tetik olmamalı, \(triggers.count) geldi")

    triggers += run(detector: &detector, seconds: 0.2, from: 0.4) { _ in 0 }
    triggers += run(detector: &detector, seconds: 0.3, from: 0.6) { _ in 50 }
    expect(triggers.count == 2, "3b: cooldown geçtikten sonra tetiklenmeli, \(triggers.count) geldi")
}

// MARK: 4 — Duraklat kilidi (§09 §3)

do {
    var detector = TiltDetector()
    detector.reset(at: 0)
    detector.lockTriggers(at: 0)
    // Telefonu alından indirme hareketi 40°'yi geçiyor ama kilit yutmalı.
    var triggers = run(detector: &detector, seconds: 0.5) { _ in 70 }
    expect(triggers.isEmpty, "4a: kilit süresince tetik olmamalı, \(triggers.count) geldi")

    triggers += run(detector: &detector, seconds: 0.5, from: 0.7) { _ in 70 }
    expect(triggers.count == 1, "4b: kilit bitince tetik yeniden çalışmalı")
}

// MARK: 5 — Tur içi yeniden kalibrasyon (§04 §2)

do {
    var detector = TiltDetector()
    detector.reset(at: 0)
    // Kullanıcı telefonu kaydırdı: açı 30°'de sabit kaldı, tetik gelmiyor.
    let triggers = run(detector: &detector, seconds: 9) { _ in 30 }
    expect(triggers.isEmpty, "5a: 30° eşiğin altında, tetik gelmemeli")
    expect(
        detector.pendingBaselineShift != nil,
        "5b: 8 sn tetiksiz ve sabit kaymada baseline güncellemesi istenmeli"
    )
    if let shift = detector.pendingBaselineShift {
        expect(abs(shift - 30) < 1, "5c: kayma miktarı ~30° olmalı, \(shift) geldi")
    }
}

do {
    var detector = TiltDetector()
    detector.reset(at: 0)
    // Aynı süre ama açı gezgin: gerçek bir kayma değil, kalibrasyon istenmemeli.
    _ = run(detector: &detector, seconds: 9) { time in 25 * sin(time) }
    expect(
        detector.pendingBaselineShift == nil,
        "5d: salınan açıda yeniden kalibrasyon istenmemeli"
    )
}

do {
    var detector = TiltDetector()
    detector.reset(at: 0)
    // Nötrde duran cihaz kalibrasyon istemez.
    _ = run(detector: &detector, seconds: 9) { _ in 2 }
    expect(detector.pendingBaselineShift == nil, "5e: nötrde yeniden kalibrasyon istenmemeli")
}

// MARK: 6 — Yumuşatma (§04 §2)

do {
    var detector = TiltDetector()
    detector.reset(at: 0)
    // Tek karelik 60°'lik el titremesi sıçraması yutulmalı: 3'lük ortalama
    // (0 + 0 + 60) / 3 = 20 < 40.
    _ = detector.update(angle: 0, at: 0)
    _ = detector.update(angle: 0, at: 1.0 / 30)
    let spike = detector.update(angle: 60, at: 2.0 / 30)
    expect(spike == nil, "6a: tek karelik sıçrama yumuşatmayla yutulmalı")
}

// MARK: 7 — Baseline kalibrasyonu (§04 §2)

do {
    var calibrator = BaselineCalibrator()
    // Hareket hâlindeki cihaz: alna götürülüyor.
    for step in 0..<10 { calibrator.add(Double(step) * 5) }
    expect(calibrator.stableBaseline == nil, "7a: hareket hâlinde baseline alınmamalı")
    expect(calibrator.fallbackBaseline != nil, "7b: yedek baseline son ölçüm olmalı")

    // Sabitlendi.
    for _ in 0..<10 { calibrator.add(12) }
    if let baseline = calibrator.stableBaseline {
        expect(abs(baseline - 12) < 0.5, "7c: sabit cihazda baseline ~12° olmalı, \(baseline) geldi")
    } else {
        expect(false, "7c: sabit cihazda baseline alınmalı")
    }
}

// MARK: 8 — Cevap sonrası eğik tutma (kelime yağmuru)

do {
    var detector = TiltDetector()
    detector.reset(at: 0)
    var triggers = run(detector: &detector, seconds: 1) { _ in 50 }
    expect(triggers.count == 1, "8a: ilk eğimde tek tetik")

    // `MotionService.resume` simülasyonu: silahsız reset, telefon hâlâ eğik.
    detector.reset(at: 1, rearm: false)
    triggers += run(detector: &detector, seconds: 1, from: 1) { _ in 50 }
    expect(triggers.count == 1, "8b: eğik resume sonrası yağmur olmamalı, \(triggers.count) geldi")

    triggers += run(detector: &detector, seconds: 0.5, from: 2) { _ in 5 }
    triggers += run(detector: &detector, seconds: 0.5, from: 2.5) { _ in 50 }
    expect(triggers.count == 2, "8c: dikleşip yeniden eğince tetiklenmeli, \(triggers.count) geldi")
}

do {
    var detector = TiltDetector()
    detector.reset(at: 0)
    var triggers = run(detector: &detector, seconds: 1) { _ in 50 }
    triggers += run(detector: &detector, seconds: 9, from: 1) { _ in 50 }
    expect(
        triggers.count == 1,
        "8d: tetik sonrası eğik tutunca ikinci kelime gelmemeli, \(triggers.count) geldi"
    )
    expect(
        detector.pendingBaselineShift != nil,
        "8e: uzun eğik tutuşta baseline kayması istenmeli"
    )
}

// MARK: Sonuç

print("\(checks) kontrol, \(failures) başarısız")
exit(failures == 0 ? 0 : 1)

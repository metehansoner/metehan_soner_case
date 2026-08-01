import Foundation

/// Kaydı engelleyen cihaz durumları — 09-kesinti-ve-sinir-durumlari.md §2.
///
/// Üç satır aynı sonuca çıkıyor (kayıt başlamaz / durur) ama sebepleri farklı ve
/// kullanıcıya sebebi söylenmezse özellik bozuk görünüyor. Bu yüzden tek bir
/// `Limit` değeri dolaşıyor: hem engel hem de gösterilecek metnin anahtarı.
///
/// Değerler anlık okunuyor, gözlemlenmiyor: üçü de kaydın **başlangıcında** bir
/// kez sorulan sorular. Kayıt sürerken ısınmayı `ReplayRecorder` kendi
/// aralığıyla yokluyor — bildirim aboneliği kurmak için tek müşteri yeterli
/// gerekçe değil.
enum DeviceConditions {

    enum Limit: String {
        /// §09 §2: pil tasarrufundayken kayıt hiç başlamıyor.
        case lowPower
        /// §04 §4.1: `.serious` seviyesinde kayıt duruyor.
        case thermal
        /// §09 §2: uygulama içi 20 kayıt / 500 MB kotası **cihazın** boş alanını
        /// görmüyordu.
        case storage

        var noticeKey: String { "replay.notice.\(rawValue)" }
    }

    /// §09 §2: cihaz depolaması bu eşiğin altındaysa kayıt başlatılmıyor.
    static let minimumFreeBytes: Int64 = 200 * 1_000_000

    /// Kaydın başlamasını engelleyen ilk durum; `nil` ise engel yok.
    static func recordingLimit() -> Limit? {
        let info = ProcessInfo.processInfo
        if info.isLowPowerModeEnabled { return .lowPower }
        if isThermallyThrottled { return .thermal }
        if let free = freeBytes(), free < minimumFreeBytes { return .storage }
        return nil
    }

    /// §04 §4.1 / §08 §5: `.serious` ve üstü. Kayıt burada duruyor, sinematik
    /// bezemeler de bu değeri okuyacak.
    static var isThermallyThrottled: Bool {
        ProcessInfo.processInfo.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue
    }

    /// "Önemli" kullanım için ayrılan boş alan: iOS'un temizlenebilir alanı da
    /// sayan değeri, `systemFreeSize`'ın aksine kullanıcının gerçekten
    /// kullanabileceği miktarı veriyor. Okunamazsa engel çıkarılmıyor —
    /// ölçemediğimiz bir sebeple özelliği kapatmak, sorunu iki katına çıkarıyor.
    static func freeBytes() -> Int64? {
        let url = URL.applicationSupportDirectory
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage
    }
}

import UIKit

/// Haptik dili — 01-tasarim-sistemi.md §4.1.
///
/// Fonksiyonlar stile göre değil **etkileşime göre** isimlendirildi. `medium()`
/// gibi bir API çağrı yerinde hangi stilin doğru olduğunu her seferinde yeniden
/// karar verdiriyor; §4.1'in tamamı "her yere `.impact(.medium)`" hatasını
/// engellemek için yazılmış bir tablo. Tablo burada tek yerde duruyor.
///
/// Üstteki tek kural: **kullanıcının başlatmadığı hiçbir şey titremez.** Scroll,
/// otomatik kelime geçişi, toast, sheet açılışı ve ekran değişimi haptik almıyor;
/// bir kullanıcı aksiyonu da en fazla bir haptik üretiyor. Geri sayım, son 10
/// saniye ve süre bitişi tablonun kendi tanımladığı istisnalar.
///
/// `CHHapticEngine` v1'de kullanılmıyor; `UIFeedbackGenerator` tabloyu karşılıyor.
@MainActor
enum Haptics {

    // MARK: Butonlar ve seçim

    /// `OYNA`, `BİLETİ AL` — alt kenardaki 3px şeridin kaybolmasıyla eşzamanlı.
    static func primaryButton() { impact(.medium) }

    /// İkincil buton, `›` satırları.
    static func secondaryButton() { impact(.light) }

    /// Deste kartı seçme — net klik: "kart PlayBar'a girdi".
    static func deckSelected() { impact(.rigid) }

    /// Seçimi kaldırma — aynı hareketin yumuşak tersi.
    static func deckDeselected() { impact(.soft) }

    /// Mod Seçimi kartı — deste seçimiyle aynı klik, aynı anlam: bir şey seçildi.
    static func modeSelected() { impact(.rigid) }

    /// Filtre chip'i, dil satırı, süre stepper adımı: bir kümede gezinmek.
    static func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    /// Stepper sınırı (30s / 180s): değer değişmedi ama dokunuş algılandı.
    static func stepperLimit() { impact(.soft, intensity: 0.4) }

    static func switchOn() { impact(.rigid, intensity: 0.8) }
    static func switchOff() { impact(.soft, intensity: 0.6) }

    /// Kilitli deste / kilitli mod — donuk bir çarpma.
    ///
    /// `.error` bilinçli olarak kullanılmıyor: kullanıcı hata yapmadı, duvara
    /// dokundu. İkisi farklı hissedilmeli.
    static func lockedWall() { impact(.rigid, intensity: 0.6) }

    // MARK: Oyun — §04 §2

    static func answerCorrect() { notify(.success) }
    static func answerSkip() { notify(.warning) }

    /// Geri sayım rakamları (3, 2, 1) — §08 A1.
    static func countdownTick() { impact(.medium) }

    /// Son 10 saniyede her saniye, tik sesiyle birlikte nabız gibi.
    static func warningTick() { impact(.light, intensity: 0.4) }

    static func timeUp() { impact(.heavy) }

    /// Klaket çubuğunun kapanması — §08 A2 "klak".
    static func clapper() { impact(.heavy) }

    // MARK: Satın alma ve maç sonu

    static func purchaseSucceeded() { notify(.success) }
    static func purchaseFailed() { notify(.error) }
    static func matchWon() { notify(.success) }

    // MARK: Hazırlık

    /// §4.1: `prepare()` çağrılmadan ilk haptik ~100 ms gecikiyor. Generator anın
    /// hemen öncesinde hazırlanıyor — butonda parmak *inince*, geri sayım
    /// başlarken, `MotionService` eşiğe yaklaşırken.
    static func prepareImpact() {
        guard isEnabled else { return }
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
    }

    static func prepareNotification() {
        guard isEnabled else { return }
        notificationGenerator.prepare()
    }

    // MARK: Altyapı

    private static var isEnabled: Bool { AppSettingsStore.shared.hapticsEnabled }

    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private static let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    private static func generator(
        for style: UIImpactFeedbackGenerator.FeedbackStyle
    ) -> UIImpactFeedbackGenerator {
        switch style {
        case .light: lightGenerator
        case .medium: mediumGenerator
        case .heavy: heavyGenerator
        case .rigid: rigidGenerator
        case .soft: softGenerator
        @unknown default: mediumGenerator
        }
    }

    private static func impact(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle,
        intensity: CGFloat = 1
    ) {
        guard isEnabled else { return }
        let generator = generator(for: style)
        generator.impactOccurred(intensity: intensity)
        // Aynı haptiğin peş peşe gelmesi sık (stepper, tik sayacı);
        // tetikten hemen sonra yeniden hazırlamak gecikmeyi bir kereye indiriyor.
        generator.prepare()
    }

    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(type)
        notificationGenerator.prepare()
    }
}

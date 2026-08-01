import AVFoundation
import Foundation

/// Retro ses paketi — 04-oyun-modlari.md §5.
///
/// API, `Haptics` gibi **etkileşime göre** isimlendirildi: çağrı yerinde hangi
/// dosyanın çalacağı yeniden karar edilmiyor. Tek kapı `soundEnabled`; iOS
/// sessiz mod anahtarına da saygı gösteriliyor çünkü kategori `.ambient`.
///
/// `.ambient` + `mixWithOthers`: kullanıcının müziğini kesmiyor. Parti
/// ortamında müzik açık olur; bu önemli (§5 son paragraf).
@MainActor
enum SoundService {
    enum Cue: String, CaseIterable {
        case curtainOpen = "sfx_curtain_open"
        case bulbFlicker = "sfx_bulb_flicker"
        case projectorLoop = "sfx_projector_loop"
        case countdownTick = "sfx_countdown_tick"
        case correctBell = "sfx_correct_bell"
        case skipClack = "sfx_skip_clack"
        case tickWarning = "sfx_tick_warning"
        case timeUp = "sfx_time_up"
        case cardSlide = "sfx_card_slide"
        case buttonTap = "sfx_button_tap"
        case winFanfare = "sfx_win_fanfare"
        case ticketStamp = "sfx_ticket_stamp"
    }

    private static var players: [Cue: AVAudioPlayer] = [:]
    private static var loopPlayer: AVAudioPlayer?
    private static var didConfigureSession = false
    private static var didPlayOpening = false

    // MARK: - Etkileşim API

    /// Splash / soğuk açılış. Oturum başına bir kez.
    static func curtainOpen() {
        guard !didPlayOpening else { return }
        didPlayOpening = true
        play(.curtainOpen)
        // Ampuller perdeyle aynı anda yanıyor; ayrı bir tetik noktası yok.
        play(.bulbFlicker, volume: 0.7)
    }

    static func countdownTick() { play(.countdownTick) }
    static func correct() { play(.correctBell) }
    static func skip() { play(.skipClack) }
    static func warningTick() { play(.tickWarning, volume: 0.85) }
    static func timeUp() { play(.timeUp) }
    static func cardSlide() { play(.cardSlide, volume: 0.7) }

    /// §08 A2: klaket çubuğunun kapanışı. §04 §5'in 12 parçalık listesinde
    /// klakete ayrı bir kayıt yok — ikisi de tahtanın tahtaya çarpması, ses
    /// tasarımı geldiğinde de aynı dosya iki yerde kullanılacak.
    static func clapper() { play(.skipClack) }
    static func buttonTap() { play(.buttonTap, volume: 0.55) }
    static func winFanfare() { play(.winFanfare) }
    static func ticketStamp() { play(.ticketStamp) }

    /// Oyun ekranı boyunca çok kısık döngü (§5 — opsiyonel ama bağlandı).
    static func startProjector() {
        guard isEnabled else { return }
        configureSessionIfNeeded()
        stopProjector()
        guard let player = makePlayer(for: .projectorLoop) else { return }
        player.numberOfLoops = -1
        player.volume = 0.12
        player.play()
        loopPlayer = player
    }

    static func stopProjector() {
        loopPlayer?.stop()
        loopPlayer = nil
    }

    /// Ayar anahtarı kapanınca veya uygulama arka plana inince.
    static func stopAll() {
        stopProjector()
        for player in players.values {
            player.stop()
        }
    }

    // MARK: - Altyapı

    private static var isEnabled: Bool { AppSettingsStore.shared.soundEnabled }

    private static func play(_ cue: Cue, volume: Float = 1) {
        guard isEnabled else { return }
        configureSessionIfNeeded()

        // Aynı cue peş peşe gelebilir (geri sayım, uyarı tiki). Bitmemiş
        // oynatıcıyı başa sarmak, ikinci bir instance üretmekten ucuz.
        if let existing = players[cue] {
            existing.volume = volume
            existing.currentTime = 0
            existing.play()
            return
        }

        guard let player = makePlayer(for: cue) else { return }
        player.volume = volume
        player.play()
        players[cue] = player
    }

    private static func makePlayer(for cue: Cue) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "caf")
        else { return nil }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        return player
    }

    private static func configureSessionIfNeeded() {
        guard !didConfigureSession else { return }
        didConfigureSession = true
        let session = AVAudioSession.sharedInstance()
        // Sessiz moda saygı + diğer uygulamaların sesini kesmeme (§5).
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    #if DEBUG
    static func debugResetOpening() { didPlayOpening = false }
    #endif
}

import AVFoundation
import Foundation


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


    static func curtainOpen() {
        guard !didPlayOpening else { return }
        didPlayOpening = true
        play(.curtainOpen)

        play(.bulbFlicker, volume: 0.7)
    }

    static func countdownTick() { play(.countdownTick) }
    static func correct() { play(.correctBell) }
    static func skip() { play(.skipClack) }
    static func warningTick() { play(.tickWarning, volume: 0.85) }
    static func timeUp() { play(.timeUp) }
    static func cardSlide() { play(.cardSlide, volume: 0.7) }


    static func clapper() { play(.skipClack) }
    static func buttonTap() { play(.buttonTap, volume: 0.55) }
    static func winFanfare() { play(.winFanfare) }
    static func ticketStamp() { play(.ticketStamp) }


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


    static func stopAll() {
        stopProjector()
        for player in players.values {
            player.stop()
        }
    }


    private static var isEnabled: Bool { AppSettingsStore.shared.soundEnabled }

    private static func play(_ cue: Cue, volume: Float = 1) {
        guard isEnabled else { return }
        configureSessionIfNeeded()


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

        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    #if DEBUG
    static func debugResetOpening() { didPlayOpening = false }
    #endif
}

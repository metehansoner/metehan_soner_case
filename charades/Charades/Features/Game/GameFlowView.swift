import SwiftUI

/// Oyun akışı — 04-oyun-modlari.md §3, yön katmanı 09-kesinti-ve-sinir-durumlari.md §1.
///
/// Tek bir view'ın fazları iki yöne bölünmüş durumda ve yön **yalnızca iki kez**
/// değişiyor: oyun girişinde landscape'e, maç sonunda portrait'e. Faz başına ayrı
/// ayrı kilit değiştirmek iOS'ta en çok görsel hata üreten yer, o yüzden kilit
/// tek bir türetilmiş değere (`LiveGame.prefersLandscape`) bağlı.
///
/// `RootView` bu view'ı `NavigationStack`in **yerine** render ediyor (§02 §5):
/// tur sırasında geri butonu ve swipe-back yok, çıkışın tek yolu duraklat.
struct GameFlowView: View {
    let game: LiveGame
    var onHowToPlay: () -> Void

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            switch game.phase {
            case .orientationPrompt:
                OrientationPromptView(
                    onLandscape: game.deviceBecameLandscape,
                    onPlayInPortrait: game.switchToPortraitPlay
                )
                .transition(.opacity)

            case .countdown:
                CountdownView(value: game.countdownValue, onTap: game.shortenCountdown)
                    .transition(.opacity)

            case .playing:
                playing

            case .paused:
                ZStack {
                    // Oyun kartı altta duruyor: duraklat bir overlay, ayrı ekran
                    // değil. Kullanıcı nerede kaldığını görüyor.
                    GameCardView(game: game)
                    PauseOverlay(
                        reason: game.pauseReason,
                        // §09 §3: takım modunda çıkış turu değil **maçı** iptal
                        // ediyor; onay metni buna göre ayrışıyor.
                        cancelsMatch: game.match != nil,
                        onResume: game.resume,
                        onRestart: game.restartRound,
                        onHowToPlay: onHowToPlay,
                        onExit: game.exit
                    )
                }
                .transition(.opacity)

            case .roundEnd:
                RoundEndView(
                    game: game,
                    onPlayAgain: game.playAgain,
                    onNextTeam: game.finishTeamTurn,
                    onExit: game.exit
                )
                .transition(.opacity)

            case .teamHandoff(let team, let player):
                if let match = game.match {
                    TeamTurnHandoffView(
                        match: match,
                        teamIndex: team,
                        player: player,
                        secondsLeft: game.handoffCountdown,
                        onReady: game.beginTeamTurn
                    )
                    // §07 §5: associated value'lu fazda view kimliği zorlanıyor,
                    // yoksa takım değişiminde geçiş animasyonu takılıyor.
                    .id(match.results.count)
                    .transition(.opacity)
                }

            case .matchEnd:
                if let match = game.match {
                    MatchEndView(match: match, onRematch: game.rematch, onExit: game.exit)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: game.phase)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            syncOrientation()
            syncBrightness()
        }
        .onChange(of: game.phase) { _, _ in
            syncOrientation()
            syncBrightness()
        }
        .onDisappear { ScreenBrightness.restore() }
        // §09 §2: arka plan, gelen çağrı ve ekran kilidi aynı yol — otomatik
        // duraklat. Genel ilke: hiçbir kesinti tur sonuçlarını yok etmiyor.
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                game.handleSceneActive()
            } else {
                ScreenBrightness.restore()
                game.handleSceneInactive()
            }
        }
    }

    private var playing: some View {
        GameCardView(game: game)
            .pauseGesture(
                // §09 §3: dokunmatik modda iki parmakla dokunma aynı zamanda bir
                // ekran yarısına dokunma demek; o modda yalnızca sürükleme.
                allowsTwoFingerTap: game.answerInput == .tilt,
                onGestureBegan: game.lockTriggersForPauseGesture,
                onPause: { game.pause(reason: .user) }
            )
            .transition(.opacity)
    }

    /// §04 §1: yalnızca `Canlandır` oynanırken ve yalnızca oyun kartında.
    /// Duraklat, tur sonu ve geri sayım normal parlaklıkta — o ekranlarda
    /// telefona bakan kişi zaten herkes.
    private func syncBrightness() {
        if game.phase == .playing, !game.mode.screenVisibleToGuesser {
            ScreenBrightness.dim()
        } else {
            ScreenBrightness.restore()
        }
    }

    private func syncOrientation() {
        if game.prefersLandscape {
            OrientationLock.shared.lockLandscape()
        } else {
            OrientationLock.shared.lockPortrait()
        }
    }
}

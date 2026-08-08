import SwiftUI

/// Oyun akışı — 04-oyun-modlari.md §3, yön katmanı 09-kesinti-ve-sinir-durumlari.md §1.
///
/// Landscape fazlar `ForcedLandscapeContainer` ile çiziliyor: pencere portrait
/// kalır, içerik 90° döner. Böylece Control Center yön kilidi açık olsa bile
/// oyun yatay düzenini korur; sistem `requestGeometryUpdate` başarısına
/// bağımlı değiliz.
///
/// `RootView` bu view'ı `NavigationStack`in **yerine** render ediyor (§02 §5):
/// tur sırasında geri butonu ve swipe-back yok, çıkışın tek yolu duraklat.
struct GameFlowView: View {
    let game: LiveGame
    var onHowToPlay: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppSettingsStore.self) private var settings
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// §03 §2 varyant C. Tam ekran paywall oyun akışının içinden açılıyor:
    /// tur sonu `NavigationStack`in yerine render edildiği için (§02 §5)
    /// kabuktaki paywall sheet'ine buradan ulaşılamıyor.
    @State private var showsSoftPaywall = false
    @State private var showsFullPaywall = false

    /// §02 ekran 18: oynatıcı tur sonu ekranının **üstünde** açılıyor, onun
    /// yerine geçmiyor. Tur sonundaki düzeltmeler oynatıcı kapanınca yerinde
    /// duruyor ve `roundEnd` zaten landscape (§09 §1) — kayıt fazının yön
    /// sözleşmesi kendiliğinden sağlanıyor.
    @State private var showsReplay = false

    var body: some View {
        ZStack {
            phaseContent

            if showsSoftPaywall {
                SoftPaywallPanel(
                    onSeeTicket: {
                        showsSoftPaywall = false
                        showsFullPaywall = true
                    },
                    onClose: { showsSoftPaywall = false }
                )
            }

            VStack {
                replayNotice
                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.22), value: game.phase)
        // Soft paywall landscape fazda (tur sonu) açılıyor; dönüşün dışında
        // kalsaydı alındaki telefonda yan okunurdu.
        .forcedLandscape(game.prefersLandscape)
        .animation(
            reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.34, dampingFraction: 0.85),
            value: showsSoftPaywall
        )
        .fullScreenCover(isPresented: $showsReplay) {
            if let reel = game.reel {
                ReplayPlayerView(
                    reel: reel,
                    onDelete: {
                        game.deleteReel()
                        showsReplay = false
                    },
                    onClose: { showsReplay = false }
                )
                .forcedLandscape()
                .environment(l10n)
                .localizedLayout()
            }
        }
        .fullScreenCover(isPresented: $showsFullPaywall) {
            PaywallView(context: .roundEnd, variant: .modal) { showsFullPaywall = false }
                // Portrait paywall: forced-landscape kısa kenarda CTA/X kesiliyordu.
                .environment(LocalizationManager.shared)
                .environment(AppSettingsStore.shared)
                .environment(SubscriptionStore.shared)
                .localizedLayout()
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            // Pencere hep portrait; landscape yalnızca view dönüşü.
            OrientationLock.shared.lockPortrait()
            syncBrightness()
        }
        .onChange(of: game.phase) { _, newPhase in
            OrientationLock.shared.lockPortrait()
            syncBrightness()
            if newPhase == .roundEnd { offerSoftPaywall() }
        }
        .onDisappear { ScreenBrightness.restore() }
        #if DEBUG
        // Simülatörde dokunuş yok; oynatıcı `-AutoScore` gibi kendiliğinden
        // açılabilsin diye.
        .onChange(of: game.reel != nil) { _, hasReel in
            guard hasReel, ProcessInfo.processInfo.arguments.contains("-AutoReplay") else { return }
            showsReplay = true
        }
        #endif
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

    @ViewBuilder
    private var phaseContent: some View {
        ZStack {
            switch game.phase {
            case .slate:
                SlateView(
                    scene: game.sceneNumber,
                    take: game.takeNumber,
                    deckTitle: deckTitle,
                    modeTitle: l10n.t(game.mode.titleKey),
                    isFull: game.isSlateFull,
                    onFinish: game.finishSlate
                )
                // §07 §5: aynı fazda ikinci kez girilen view kimliksiz kalırsa
                // (`YENİDEN`) `task` yeniden çalışmıyor ve klaket donuyor.
                .id("\(game.sceneNumber)-\(game.takeNumber)")
                .transition(.opacity)

            case .countdown:
                CountdownView(
                    value: game.countdownValue,
                    reel: game.sceneNumber,
                    onTap: game.shortenCountdown
                )
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
                    onExit: game.exit,
                    onWatchReplay: { showsReplay = true }
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
                    MatchEndView(
                        match: match,
                        hasReels: game.matchHasReels,
                        onRematch: game.rematch,
                        onArchive: game.openArchive,
                        onExit: game.exit
                    )
                        .transition(.opacity)
                }
            }
        }
    }

    /// §09 §2: düşük güç modu, ısınma ve dolu disk kaydı sessizce iptal
    /// ediyordu. Sebep bir kez, oyunu kesmeden söyleniyor — telefon o an
    /// birinin alnında, modal açılamaz.
    @ViewBuilder
    private var replayNotice: some View {
        if let key = ReplayRecorder.shared.noticeKey {
            Text(l10n.t(key))
                .font(AppFont.ui(10, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textCream)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    Capsule()
                        .fill(AppColors.bgFilmBlack.opacity(0.92))
                        .overlay {
                            Capsule().strokeBorder(AppColors.accentGold.opacity(0.4), lineWidth: 1)
                        }
                }
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task {
                    try? await Task.sleep(for: .seconds(4))
                    ReplayRecorder.shared.clearNotice()
                }
        }
    }

    /// Klaketin `DESTE` satırı ve başlık kartının büyük yazısı. Arşiv film
    /// başlığıyla aynı kural (§04 §4.3): tek deste adıyla, çoklu seçim `MIX`,
    /// deste olmayan modlar (Kelime Sepeti) mod adıyla anılıyor.
    private var deckTitle: String {
        if game.deckIDs.count == 1, let deck = DeckCatalog.deck(game.deckIDs[0]) {
            return l10n.t(deck.titleKey)
        }
        if game.deckIDs.count > 1 { return l10n.t("mode.mix.title") }
        return l10n.t(game.mode.titleKey)
    }

    private var playing: some View {
        GameCardView(game: game)
            .pauseGesture(
                // Eğ modunda ekran yarıları cevap vermiyor; iki parmakla
                // duraklatma yine de kapalı — sürükleme her iki modda da çalışıyor
                // ve dokunmatikte yarılarla çakışıyordu (§09 §3).
                allowsTwoFingerTap: false,
                onGestureBegan: game.lockTriggersForPauseGesture,
                onPause: { game.pause(reason: .user) }
            )
            .transition(.opacity)
    }

    /// §03 §2 varyant C koşulu: `!isPremium && !softPaywallSeen && roundsCompleted >= 1`.
    /// Tur sonuna girerken `recordRoundPlayed()` çalıştığı için sayaç burada
    /// zaten en az 1.
    private func offerSoftPaywall() {
        guard settings.shouldShowSoftPaywall(isPremium: subscriptions.isPremium) else { return }
        settings.markSoftPaywallSeen()
        showsSoftPaywall = true
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
}

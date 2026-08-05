import StoreKit
import SwiftData
import SwiftUI

/// Navigasyon kabuğu — 02-ekran-akisi.md §5.
///
/// Tek `NavigationStack`, `TabView` yok. Deste Detayı ve Ayarlar sheet olarak
/// sunuluyor; paywall §03 §2'ye göre tam ekran (`fullScreenCover`). Oyun
/// akışı path'e **push edilmiyor**: `LiveGame` oluştuğunda `NavigationStack`in
/// tamamının yerine `GameFlowView` render ediliyor (P4), böylece oyun sırasında
/// geri butonu ve swipe-back olmuyor.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @Environment(AppSettingsStore.self) private var settings
    @Environment(SubscriptionStore.self) private var subscriptions

    @State private var router = AppRouter()
    @State private var setup = GameSetup()
    @State private var liveGame: LiveGame?
    @State private var isShowingOnboarding = false
    @State private var wantsPaywallAfterSettings = false
    @State private var wantsArchiveAfterSettings = false

    /// §08 A3: perde açılışı yalnızca **soğuk açılışta**. `RootView` arka
    /// plandan dönüşte yeniden kurulmadığı için bayrak kendiliğinden bir kez
    /// çalışıyor; ayrıca bir "ilk kez mi" kaydı tutmaya gerek yok.
    #if DEBUG
    // Ekran görüntüsü ve akış denemelerinde 1,2 saniye her seferinde bekleniyor.
    @State private var isRevealing = !ProcessInfo.processInfo.arguments.contains("-SkipSplash")
    #else
    @State private var isRevealing = true
    #endif

    var body: some View {
        @Bindable var router = router

        return ZStack {
            if let liveGame {
                GameFlowView(game: liveGame) {
                    router.openHowToPlay(for: liveGame.mode)
                }
                .transition(.opacity)
            } else {
                shell
            }
        }
        .animation(.easeInOut(duration: 0.25), value: liveGame == nil)
        // Kurulum zinciri kabuğun değil kökün üstünde: Nasıl Oynanır duraklat
        // menüsünden de açılıyor ve oyun sırasında `NavigationStack` render
        // edilmiyor.
        .sheet(isPresented: isShowingSetup) { setupSheet }
        // §03 §1: onboarding ana ekranın **üstünde**, arkası bulanık değil.
        // Paywall `onDismiss`te açılıyor: sheet kapanmadan fullScreenCover
        // aynı tick'te açılırsa sessizce yutuluyor.
        .sheet(isPresented: $isShowingOnboarding, onDismiss: offerOnboardingPaywall) {
            OnboardingSheet { isShowingOnboarding = false }
                .environment(LocalizationManager.shared)
                .environment(settings)
                .localizedLayout()
        }
        .task(id: promptGateID) { await offerHomePrompt() }
        .overlay {
            if isRevealing {
                CurtainRevealView { finishReveal() }
                    .environment(LocalizationManager.shared)
                    // Perde kalkarken altındaki ana ekran zaten yerinde;
                    // ikinci bir geçiş animasyonu üst üste biniyor.
                    .transition(.identity)
            }
        }
    }

    /// Onboarding perdeden **sonra** açılıyor: sheet'in perdenin arkasında
    /// yükselmesi, perde kalkınca yarı yolda yakalanmış bir kart bırakıyordu.
    private func finishReveal() {
        isRevealing = false
        startFirstRunIfNeeded()
    }

    // MARK: İlk açılış ve istemler — §03 §1, §09 §9

    /// §02 §3 akış diyagramı: Onboarding tamamlandı mı? Hayır → 3 adım sheet →
    /// paywall → ana ekran.
    private func startFirstRunIfNeeded() {
        guard !settings.onboardingDone, !isShowingOnboarding else { return }
        isShowingOnboarding = true
    }

    /// §03 §1: onboarding'i paywall izliyor. `ATLA` görünür olduğu için bu
    /// "hard" bir duvar değil; premium kullanıcıda (geri yükleme sonrası) ve
    /// paywall bir kez görülmüşse hiç açılmıyor.
    private func offerOnboardingPaywall() {
        guard settings.onboardingDone, !settings.paywallSeen, !subscriptions.isPremium else { return }
        router.openPaywall(.vipButton, variant: .onboarding)
    }

    /// Ana ekranda oyun, sheet ve paywall yokken. İstem yalnızca burada çıkıyor.
    private var isHomeIdle: Bool {
        settings.onboardingDone
            && !isRevealing
            && !isShowingOnboarding
            && liveGame == nil
            && router.paywall == nil
            && router.setupStep == nil
    }

    private var canOfferRateUs: Bool {
        !settings.rateUsPrompted && settings.roundsPlayed >= 1
    }

    /// Durum değişince sayaç sıfırdan başlasın diye `task(id:)` anahtarı: oyuna
    /// girip çıkan kullanıcıda 8 saniye yeniden işliyor.
    private var promptGateID: String {
        "\(isHomeIdle)-\(settings.notificationPrompted)-\(canOfferRateUs)"
    }

    /// §09 §9: oturum başına tek istem, öncelik sırası bildirim izni > puanla
    /// bizi. Sekiz saniye § `03` §1'den — izin, kullanıcı yerleştikten sonra
    /// soruluyor; açılışta sorulan izin reddediliyor.
    private func offerHomePrompt() async {
        let prompts = PromptCoordinator.shared
        guard isHomeIdle, prompts.shown == nil else { return }
        guard !settings.notificationPrompted || canOfferRateUs else { return }

        try? await Task.sleep(for: .seconds(8))
        guard !Task.isCancelled, isHomeIdle, prompts.shown == nil else { return }

        if !settings.notificationPrompted {
            let status = await NotificationService.authorizationStatus()
            settings.markNotificationPrompted()
            if status == .notDetermined, prompts.claim(.notifications) {
                await NotificationService.requestAuthorization()
                return
            }
            // İzin zaten karara bağlanmış: kota harcanmadı, sıradaki isteme geçiliyor.
        }

        guard canOfferRateUs, prompts.claim(.rateUs) else { return }
        settings.markRateUsPrompted()
        requestReview()
    }

    // MARK: Kurulum zinciri — §02 §3

    private var isShowingSetup: Binding<Bool> {
        Binding(
            get: { router.setupStep != nil },
            set: { if !$0 { router.closeSetup() } }
        )
    }

    /// Mod+ayar ve Nasıl Oynanır aynı sheet'in içinde; sheet bir kez açılıyor.
    @ViewBuilder
    private var setupSheet: some View {
        Group {
            switch router.setupStep {
            case .mode:
                ModeSelectSheet(
                    onClose: router.closeSetup,
                    onPlay: finishSetup,
                    onNeedsSideSetup: openSideSetup
                )
                .presentationDetents([.large])

            case .howToPlay(let mode, let continuesToGame):
                HowToPlaySlider(
                    mode: mode,
                    startsRound: continuesToGame,
                    onClose: router.closeSetup,
                    onFinish: {
                        router.closeSetup()
                        if continuesToGame { startGame() }
                    }
                )
                .presentationDetents([.fraction(0.78)])

            case nil:
                Color.clear
            }
        }
        .environment(LocalizationManager.shared)
        .environment(AppSettingsStore.shared)
        .environment(SubscriptionStore.shared)
        .environment(router)
        .environment(setup)
        .animation(.easeInOut(duration: 0.2), value: router.setupStep)
    }

    /// Takım / Kelime Sepeti / Mix kurulumu — sheet kapanır, tam ekran rota açılır.
    private func openSideSetup(for mode: GameMode) {
        // §04 §1: `ownWords` deste seçmiyor; önceden seçilmiş deste düşüyor.
        if !mode.needsDeckSelection {
            setup.clearSelection()
            router.closeSetup()
            router.push(.wordBasket)
            return
        }
        if mode.usesTeams {
            router.closeSetup()
            router.push(.teamSetup(resumesModeSelect: true))
            return
        }
        if mode == .mix {
            router.closeSetup()
            router.push(.mix)
        }
    }

    /// OYNA: ilk kez Nasıl Oynanır, değilse doğrudan oyun.
    private func finishSetup() {
        let settings = AppSettingsStore.shared
        guard settings.hasSeenHowToPlay(setup.mode) else {
            router.setupStep = .howToPlay(mode: setup.mode, continuesToGame: true)
            return
        }
        router.closeSetup()
        startGame()
    }

    private var shell: some View {
        @Bindable var router = router

        return NavigationStack(path: $router.path) {
            DecksHomeView(onPlay: router.beginSetup)
                .navigationBarHidden(true)
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                        .navigationBarHidden(true)
                        // Native swipe-back `navigationBarHidden` ile kayboluyor.
                        .onSwipeBack { router.pop() }
                }
                .onAppear {
                    #if DEBUG
                    applyDebugArguments()
                    // İlk açılış akışını normalde perde bitince `finishReveal`
                    // başlatıyor; `-SkipSplash` perdeyi hiç çizmediği için o
                    // çağrı gelmiyordu ve `-FirstRun` sessizce ana ekranda
                    // kalıyordu.
                    if !isRevealing { startFirstRunIfNeeded() }
                    #endif
                }
        }
        .tint(AppColors.accentAmber)
        // Sheet'ler ayrı presentation context'inde açılıyor; `@Environment`
        // mirası buraya kadar geliyor ama sheet içeriğine taşınmıyor. Ortamı
        // içeride yeniden vermek zorunlu — aksi hâlde `AppRouter` fatal error.
        .environment(router)
        .environment(setup)
        .sheet(
            item: $router.deckDetailID.deckBinding,
            onDismiss: router.deckDetailDismissed
        ) { deck in
            DeckDetailSheet(deck: deck)
                .environment(LocalizationManager.shared)
                .environment(AppSettingsStore.shared)
                .environment(SubscriptionStore.shared)
                .environment(router)
                .environment(setup)
        }
        .sheet(isPresented: $router.isShowingSettings, onDismiss: resumeAfterSettings) {
            SettingsSheet(
                onManageSubscription: manageSubscription,
                onUpgrade: requestPaywallAfterSettings,
                onOpenArchive: requestArchiveAfterSettings
            )
            .environment(LocalizationManager.shared)
            .environment(settings)
            .environment(subscriptions)
        }
        .fullScreenCover(item: $router.paywall) { context in
            paywall(for: context)
        }
        // §09 §9: modal paywall oturum kotası dolduğunda kilitli içerik dokunuşu
        // yalnızca bu kısa uyarıyı gösteriyor.
        .overlay(alignment: .bottom) {
            LockedNotice(text: router.lockedNotice) { router.lockedNotice = nil }
        }
    }

    /// §06 §1 satır 12: premium ise sistem abonelik sayfası, değilse paywall.
    /// Paywall tam ekran, ayarlar sheet; ikisi aynı anda sunulamadığı için
    /// istek işaretlenip ayarlar kapandıktan sonra açılıyor.
    private func manageSubscription() {
        guard subscriptions.isPremium else {
            requestPaywallAfterSettings()
            return
        }
        subscriptions.openManageSubscriptions()
    }

    private func requestPaywallAfterSettings() {
        wantsPaywallAfterSettings = true
        router.isShowingSettings = false
    }

    /// Arşiv bir sheet değil, path'e giren tam ekran (§02 §5). Sheet açıkken
    /// push edilirse ekran arkada açılıyor ve kullanıcı ayarları kapatana kadar
    /// görmüyor.
    private func requestArchiveAfterSettings() {
        wantsArchiveAfterSettings = true
        router.isShowingSettings = false
    }

    private func resumeAfterSettings() {
        if wantsPaywallAfterSettings {
            wantsPaywallAfterSettings = false
            router.openPaywall(.vipButton)
        }
        if wantsArchiveAfterSettings {
            wantsArchiveAfterSettings = false
            Analytics.replayArchiveOpen(entry: .settings, reelCount: ReplayStore.reelCount())
            router.push(.archive)
        }
    }

    private func paywall(for context: PaywallContext) -> some View {
        // §03 §2 varyant A: "tam ekran". Sheet detent'i afiş duvarını kesiyordu.
        PaywallView(context: context, variant: router.paywallVariant) { router.paywall = nil }
            .environment(LocalizationManager.shared)
            .environment(AppSettingsStore.shared)
            .environment(SubscriptionStore.shared)
            .localizedLayout()
    }

    /// §02 §5: oyun path'e push edilmiyor, `NavigationStack`in yerine geçiyor.
    private func startGame() {
        let settings = AppSettingsStore.shared
        // §02 §6: motion sensörü yoksa / çalışmıyorsa otomatik dokunmatik.
        let canTilt = MotionService.shared.isAvailable && !settings.prefersTouchAnswers
        // §09 §8: tur boyunca gün dönse bile bugünün bedava destesi kilitlenmiyor.
        DeckCatalog.pinDailyFreeDeck()
        liveGame = LiveGame(
            mode: setup.mode,
            deckIDs: setup.selectedDeckIDs,
            duration: setup.effectiveDuration(userPreference: settings.roundDuration),
            difficulty: setup.difficulty ?? settings.difficulty,
            answerInput: canTilt ? .tilt : .touch,
            playsInPortrait: false,
            roundsPlayed: settings.roundsPlayed,
            match: makeMatch(),
            customCards: customCards(),
            onExit: endGame
        )
    }

    /// §05 §7'nin iki kapısı da aynı yere çıkıyor: kullanıcının kendi kelimeleri
    /// katalog kartlarıyla aynı tipte havuza giriyor.
    private func customCards() -> [Card] {
        let language = LocalizationManager.shared.localeCode
        if setup.mode == .ownWords {
            return setup.basketCards(language: language)
        }
        guard let id = setup.customDeckID,
              let deck = try? modelContext.fetch(FetchDescriptor<CustomDeck>())
                  .first(where: { $0.uuid == id })
        else { return [] }
        return deck.toCards()
    }

    /// Takım adları maça girerken bir kez çözülüyor (§09 §5): boş bırakılan
    /// takım numarasını alıyor, model lokalizasyona bağlanmıyor.
    private func makeMatch() -> TeamMatch? {
        guard setup.mode.usesTeams else { return nil }
        let l10n = LocalizationManager.shared
        return TeamMatch(
            teams: setup.matchTeams { l10n.t("teams.defaultName", ["index": "\($0)"]) },
            roundsPerTeam: setup.roundsPerTeam
        )
    }

    private func endGame(_ exit: LiveGame.Exit) {
        liveGame = nil
        DeckCatalog.unpinDailyFreeDeck()
        OrientationLock.shared.lockPortrait()
        // §02 §3: maç sonundaki `TEKRAR OYNA` Takım Kurulumu'na dönüyor —
        // o ekran path'te duruyor, dokunmak yeni maça yetiyor.
        switch exit {
        case .home:
            router.popToRoot()
        case .teamRematch:
            break
        case .archive:
            Analytics.replayArchiveOpen(entry: .matchEnd, reelCount: ReplayStore.reelCount())
            router.popToRoot()
            router.push(.archive)
        }
    }

    #if DEBUG
    /// İçeriği üretilmiş desteler (§10 §4) — boş havuzla tur başlamıyor.
    private static let debugMixDecks = ["party", "movieClassics", "cities"]

    private static let debugWords = [
        "Kahve molası", "Zoom", "Terfi", "Mesai", "Bordro", "Yazıcı",
        "Toplantı", "Ayşe'nin köpeği", "Müdürün arabası", "Mola",
    ]

    /// Sepet ve custom deste tohumu: sabit Türkçe liste mağaza karesinde ve
    /// yabancı dil denemelerinde yamalı duruyor. Ücretsiz destenin kendi
    /// kartları o dilde hazır — tohum onları ödünç alıyor.
    private static func debugSeedWords(_ count: Int) -> [String] {
        let language = LocalizationManager.shared.localeCode
        let words = CardBank.shared
            .cards(in: DeckCatalog.freeDeckID)
            .prefix(count)
            .map { $0.text(for: language) }
        return words.isEmpty ? Array(debugWords.prefix(count)) : Array(words)
    }

    /// Simülatör doğrulaması. Tilt sensörü ve ekran döndürme simülatörde
    /// olmadığı için oyun fazlarına başka türlü girilemiyor.
    ///
    ///   -DeckDetail party      deste detayı sheet'i
    ///   -Mode rapid            oyun modu (varsayılan `classic`)
    ///   -ModeSelect            Mod + tur ayarı sheet'i
    ///   -Preset party          Aynı sheet, verilen deste seçili
    ///   -HowTo                 Nasıl Oynanır slider'ı
    ///   -StartGame a,b         turu başlat (forced-landscape); virgülle Mix
    ///   -TouchAnswers          dokunmatik cevap (tilt yerine ekran yarıları)
    ///   -ShortRound            süre 12 sn (tur sonu ekranını hızlı görmek için)
    ///   -Premium               abonelik açık (kilitli modları denemek için)
    ///   -Free                  aboneliği kapatır (`-Premium` kalıcı yazıyor)
    ///   -TeamRoster            takım modu + örnek takım/oyuncu adları, 1 tur
    ///   -TeamSetup             Takım Kurulumu ekranı
    ///   -MixSelection [a,b]    premium + verilen desteler seçili (varsayılan 3)
    ///   -MixSetup              Mix Kurulumu ekranı
    ///   -SavedMix              örnek bir kayıtlı karışım ekler
    ///   -CustomDeck [n]        örnek custom deste ekler (n kelime, varsayılan 6)
    ///   -CustomList            Kendi Destelerim ekranı
    ///   -CustomEditor          örnek destenin editörü
    ///   -Basket [n]            sepete n örnek kelime koyar (varsayılan 7)
    ///   -WordBasket            Kelime Sepeti ekranı
    ///   -Paywall [bağlam]      modal paywall (`deck:party`, `mode:mix`, `mix`,
    ///                          `customDeck`; varsayılan `vip`)
    ///   -PaywallOnboarding     varyant A (afiş duvarı + ATLA)
    ///   -MockOffers            RevenueCat anahtarı olmadan örnek plan kartları
    ///   -SoftPaywall           tur sonu yumuşak önerisini yeniden tetikler
    ///   -Lapse                 abonelik düşmüş gibi davranır (bilgi kartı)
    ///   -FirstRun [adım]       onboarding'i baştan açar (1–3, varsayılan 1)
    ///   -NoFirstRun            onboarding/paywall/istem zincirini kapalı açar
    ///   -NoKeyboard            kelime girişini odaksız açar (klavye kapalı)
    ///   -TouchOnboarding       adım 3'ün dokunmatik hâli
    ///   -TiltOnboarding        adım 3'ün eğme hâli (simülatörde sensör yok)
    ///   -HomePrompts           ana ekrandaki 8 sn'lik istem zincirini tetikler
    ///   -Settings              Ayarlar sheet'i
    ///   -SeedArchive [n]       kaydedilmiş bir makarayı n kez çoğaltır
    ///   -Archive               Film Arşivi ekranı
    ///   -ArchivePlayer         arşivden en yeni makaranın oynatıcısı
    ///   -MuteSound             ses paketini kapatır (ayar anahtarı)
    ///   -Lang <kod>            dili değiştirir (taşma ve RTL denetimi)
    private func debugPaywallContext(_ raw: String?) -> PaywallContext {
        guard let raw, !raw.hasPrefix("-") else { return .vipButton }
        let parts = raw.split(separator: ":", maxSplits: 1)
        switch (parts.first, parts.count) {
        case ("deck", 2): return .lockedDeck(String(parts[1]))
        case ("mode", 2): return .lockedMode(String(parts[1]))
        case ("mix", 1): return .mix
        case ("customDeck", 1): return .customDeck
        default: return .vipButton
        }
    }

    private func applyDebugArguments() {
        let arguments = ProcessInfo.processInfo.arguments

        func value(after flag: String) -> String? {
            arguments.drop(while: { $0 != flag }).dropFirst().first
        }

        /// Virgülle ayrılmış liste Mix'i tek argümanla kurabilsin diye.
        func deckIDs(_ raw: String) -> [String] {
            raw.split(separator: ",").map(String.init)
        }

        func savedMixCount() -> Int {
            (try? modelContext.fetchCount(FetchDescriptor<SavedMix>())) ?? 0
        }

        func customDeckCount() -> Int {
            (try? modelContext.fetchCount(FetchDescriptor<CustomDeck>())) ?? 0
        }

        // `-Premium` UserDefaults'a yazıyor; kilitli hâli görmek için açık bir
        // kapatma bayrağı gerekiyor, yoksa sonraki açılışlar premium kalıyor.
        if arguments.contains("-Premium") {
            SubscriptionStore.shared.debugPremiumOverride = true
            SubscriptionStore.shared.debugSetRenewalDate()
        } else if arguments.contains("-Free") {
            SubscriptionStore.shared.debugPremiumOverride = false
        }
        if arguments.contains("-MockOffers") {
            SubscriptionStore.shared.debugLoadSampleOffers()
        }
        if arguments.contains("-TouchOnboarding") {
            AppSettingsStore.shared.prefersTouchAnswers = true
        }
        // Taşma ve RTL denetimi için: Almanca/Fince en uzun, Arapça sağdan sola.
        if let code = value(after: "-Lang") {
            LocalizationManager.shared.setLanguage(code)
        }
        if arguments.contains("-MuteSound") {
            AppSettingsStore.shared.soundEnabled = false
        }
        // Simülatörde kamera yok; `-FakeReplay` sentetik motoru açıyor ve bu
        // bayrak da ayarı + izin akışının sonucunu hazır getiriyor (§ `04` §4.1).
        if arguments.contains("-FakeReplay") {
            SubscriptionStore.shared.debugPremiumOverride = true
            AppSettingsStore.shared.replayEnabled = true
        }
        // Arşiv ancak kayıt varken bir şey gösteriyor; tohumlama gerçek bir
        // makarayı çoğaltıyor (§ `04` §4.3 gruplama ve kota denetimi için).
        if arguments.contains("-SeedArchive") {
            let count = value(after: "-SeedArchive").flatMap(Int.init) ?? 5
            ReplayStore.debugSeed(copies: count, words: Self.debugSeedWords(3))
        }
        if arguments.contains("-NotificationsOff") {
            AppSettingsStore.shared.notificationsEnabled = false
        } else if arguments.contains("-NotificationsOn") {
            AppSettingsStore.shared.notificationsEnabled = true
        }
        if arguments.contains("-HomePrompts") {
            AppSettingsStore.shared.debugReplayHomePrompts()
            PromptCoordinator.shared.debugReset()
        }
        // Mağaza karelerinde ilk açılış sheet'i her ekranın üstünü kapatıyor.
        if arguments.contains("-NoFirstRun") {
            AppSettingsStore.shared.debugSkipFirstRun()
        }
        if arguments.contains("-FirstRun") {
            AppSettingsStore.shared.debugResetFirstRun()
            PromptCoordinator.shared.debugReset()
            let step = value(after: "-FirstRun").flatMap(Int.init) ?? 1
            AppSettingsStore.shared.storeOnboardingStep(max(step, 1) - 1)
        }
        if arguments.contains("-Lapse") {
            SubscriptionStore.shared.debugSimulateLapse()
            AppSettingsStore.shared.debugResetOneTimePrompts()
        }
        if arguments.contains("-SoftPaywall") {
            SubscriptionStore.shared.debugPremiumOverride = false
            AppSettingsStore.shared.debugResetOneTimePrompts()
        }
        if let raw = value(after: "-Mode"), let mode = GameMode(rawValue: raw) {
            setup.mode = mode
        }
        if arguments.contains("-TouchAnswers") {
            AppSettingsStore.shared.prefersTouchAnswers = true
        }
        if arguments.contains("-ShortRound") {
            AppSettingsStore.shared.roundDuration = 12
        }
        // Perde arası ve jenerik ancak dolu bir kadroyla görülebiliyor: oyuncu
        // adı yoksa iki satır takım adına düşüyor.
        if arguments.contains("-TeamRoster") {
            SubscriptionStore.shared.debugPremiumOverride = true
            setup.mode = .teams
            let l10n = LocalizationManager.shared
            setup.teams = [
                Team(
                    name: l10n.t("teams.defaultName", ["index": "1"]),
                    players: Array(ReplayStore.debugPlayerNames.prefix(2))
                ),
                Team(
                    name: l10n.t("teams.defaultName", ["index": "2"]),
                    players: Array(ReplayStore.debugPlayerNames.dropFirst(2).prefix(2))
                )
            ]
            setup.roundsPerTeam = 1
        }

        // Mix premium; kurulum ekranını duvarsız görebilmek için.
        if arguments.contains("-MixSelection") {
            SubscriptionStore.shared.debugPremiumOverride = true
            setup.select(all: value(after: "-MixSelection").map(deckIDs) ?? Self.debugMixDecks)
            setup.mode = .mix
        }
        if arguments.contains("-SavedMix"), savedMixCount() == 0 {
            modelContext.insert(SavedMix(name: "Cuma Gecesi", deckIDs: Self.debugMixDecks))
        }

        if arguments.contains("-CustomDeck"), customDeckCount() == 0 {
            let count = value(after: "-CustomDeck").flatMap(Int.init) ?? 6
            let deck = CustomDeck(
                name: "Ofis Muhabbeti",
                languageCode: LocalizationManager.shared.localeCode
            )
            modelContext.insert(deck)
            deck.replaceWords(Self.debugSeedWords(count))
            modelContext.persistCustomDecks()
        }
        if arguments.contains("-Basket") {
            let count = value(after: "-Basket").flatMap(Int.init) ?? 7
            setup.basketWords = Self.debugSeedWords(count)
        }

        if arguments.contains("-Settings") {
            router.isShowingSettings = true
        } else if arguments.contains("-Archive") {
            router.push(.archive)
        } else if arguments.contains("-ArchivePlayer") {
            guard let id = ReplayStore.allReels().first?.id else { return }
            router.push(.archive)
            router.push(.archivePlayer(id))
        } else if arguments.contains("-PaywallOnboarding") {
            router.openPaywall(.vipButton, variant: .onboarding)
        } else if arguments.contains("-Paywall") {
            router.openPaywall(debugPaywallContext(value(after: "-Paywall")))
        } else if arguments.contains("-CustomList") {
            router.push(.customList)
        } else if arguments.contains("-CustomEditor") {
            let deck = (try? modelContext.fetch(FetchDescriptor<CustomDeck>()))?.first
            router.push(.customEditor(deck?.uuid.uuidString))
        } else if arguments.contains("-WordBasket") {
            setup.mode = .ownWords
            router.push(.wordBasket)
        } else if arguments.contains("-MixSetup") {
            router.push(.mix)
        } else if arguments.contains("-TeamSetup") {
            router.push(.teamSetup(resumesModeSelect: false))
        } else if let id = value(after: "-DeckDetail") {
            router.openDeckDetail(id)
        } else if arguments.contains("-ModeSelect") {
            router.beginSetup()
        } else if let ids = value(after: "-Preset") {
            setup.select(all: deckIDs(ids))
            router.setupStep = .mode
        } else if arguments.contains("-HowTo") {
            router.openHowToPlay(for: setup.mode)
        } else if let ids = value(after: "-StartGame") {
            setup.select(all: deckIDs(ids))
            startGame()
        } else if let id = value(after: "-SelectDeck") {
            setup.select(only: id)
        }
    }
    #endif

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .mix:
            MixSetupView { router.setupStep = .mode }
        case .customList:
            CustomDeckListView()
        case .customEditor(let id):
            CustomDeckEditorView(deckID: id.flatMap(UUID.init(uuidString:)))
        case .wordBasket:
            WordBasketView { router.setupStep = .mode }
        case .teamSetup(let resumesModeSelect):
            TeamSetupView(resumesModeSelect: resumesModeSelect) {
                if resumesModeSelect {
                    router.setupStep = .mode
                } else {
                    router.pop()
                }
            }
        case .archive:
            ArchiveView()
        case .archivePlayer(let id):
            ArchivePlayerScreen(reelID: id)
        }
    }
}

/// Rota ve sheet bağlantıları P3'te kuruluyor ama ekranların kendisi kendi
/// paketlerinde geliyor. Boş `EmptyView` yerine hangi paketi beklediğini
/// söyleyen bir yer tutucu duruyor — akış şimdiden uçtan uca gezilebilsin.
private struct PlaceholderScreen: View {
    let titleKey: String
    let packageNote: String
    var detail: String?

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            VelvetBackground()
            PlaceholderContent(title: l10n.t(titleKey), packageNote: packageNote, detail: detail)
        }
        .overlay(alignment: .topLeading) {
            BackNavButton(
                tint: AppColors.accentBrass,
                accessibilityLabel: l10n.t("common.back")
            ) {
                router.pop()
            }
            .padding(.leading, 6)
        }
    }
}

private struct PlaceholderSheet: View {
    let titleKey: String
    let packageNote: String
    var detail: String?

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        ZStack {
            VelvetBackground(showsCurtain: true)
            PlaceholderContent(title: l10n.t(titleKey), packageNote: packageNote, detail: detail)
        }
        .presentationDetents([.large])
        .presentationCornerRadius(28)
    }
}

private struct PlaceholderContent: View {
    let title: String
    let packageNote: String
    var detail: String?

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .textStyle(.screenTitle)
                .foregroundStyle(AppColors.textCream)

            Text(packageNote)
                .textStyle(.sectionLabel)
                .foregroundStyle(AppColors.accentGold)

            if let detail {
                Text(detail)
                    .textStyle(.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .multilineTextAlignment(.center)
        .padding(32)
    }
}

private extension Binding where Value == String? {
    /// Router destenin id'sini taşıyor (rota kimliği string olmalı), sheet ise
    /// `Identifiable` bir öğe istiyor.
    var deckBinding: Binding<DeckDef?> {
        Binding<DeckDef?>(
            get: { wrappedValue.flatMap(DeckCatalog.deck) },
            set: { wrappedValue = $0?.id }
        )
    }
}

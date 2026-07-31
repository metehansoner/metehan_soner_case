import SwiftData
import SwiftUI

/// Navigasyon kabuğu — 02-ekran-akisi.md §5.
///
/// Tek `NavigationStack`, `TabView` yok. Deste Detayı, Ayarlar ve paywall
/// sheet olarak sunuluyor ve path'e girmiyor. Oyun akışı da path'e **push
/// edilmiyor**: `LiveGame` oluştuğunda `NavigationStack`in tamamının yerine
/// `GameFlowView` render ediliyor (P4), böylece oyun sırasında geri butonu ve
/// swipe-back olmuyor.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var router = AppRouter()
    @State private var setup = GameSetup()
    @State private var liveGame: LiveGame?

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
    }

    // MARK: Kurulum zinciri — §02 §3

    private var isShowingSetup: Binding<Bool> {
        Binding(
            get: { router.setupStep != nil },
            set: { if !$0 { router.closeSetup() } }
        )
    }

    /// Üç adım aynı sheet'in içinde yer değiştiriyor; sheet bir kez açılıyor.
    @ViewBuilder
    private var setupSheet: some View {
        Group {
            switch router.setupStep {
            case .mode:
                ModeSelectSheet(onSelect: chooseMode, onClose: router.closeSetup)
                    .presentationDetents([.fraction(0.88)])

            case .preset:
                RoundPresetSheet(
                    onBack: { router.setupStep = .mode },
                    onClose: router.closeSetup,
                    onPlay: finishPreset
                )
                .presentationDetents([.fraction(0.62)])

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

    private func chooseMode(_ mode: GameMode) {
        setup.mode = mode

        // §04 §1: `ownWords` deste seçmiyor, kelime kaynağı kullanıcı. Mod
        // Seçimi'nden gelindiğinde önceden seçilmiş deste **düşüyor** —
        // kaynak değişti.
        if !mode.needsDeckSelection {
            setup.clearSelection()
            router.closeSetup()
            router.push(.wordBasket)
            return
        }
        if mode.usesTeams {
            router.closeSetup()
            router.push(.teamSetup)
            return
        }
        // Mix kurulumu (2+ deste, karışım önizlemesi) ayrı bir ekran; seçim
        // zaten Mix'e yetiyorsa oraya uğramaya gerek yok.
        if mode == .mix, !setup.isMix {
            router.closeSetup()
            router.push(.mix)
            return
        }

        router.setupStep = .preset
    }

    /// §02 §3: Tur Ön Ayar'dan sonra Nasıl Oynanır **ilk kez** araya giriyor.
    private func finishPreset() {
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
        .sheet(isPresented: $router.isShowingSettings) {
            PlaceholderSheet(titleKey: "settings.title", packageNote: "P12")
                .environment(LocalizationManager.shared)
        }
        .sheet(item: $router.paywall) { context in
            PlaceholderSheet(titleKey: "paywall.title", packageNote: "P10", detail: context.id)
                .environment(LocalizationManager.shared)
        }
    }

    /// §02 §5: oyun path'e push edilmiyor, `NavigationStack`in yerine geçiyor.
    private func startGame() {
        let settings = AppSettingsStore.shared
        // §02 §6: motion sensörü yoksa / çalışmıyorsa otomatik dokunmatik.
        let canTilt = MotionService.shared.isAvailable && !settings.prefersTouchAnswers
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
        OrientationLock.shared.lockPortrait()
        // §02 §3: maç sonundaki `TEKRAR OYNA` Takım Kurulumu'na dönüyor —
        // o ekran path'te duruyor, dokunmak yeni maça yetiyor.
        if exit == .home { router.popToRoot() }
    }

    #if DEBUG
    /// İçeriği üretilmiş desteler (§10 §4) — boş havuzla tur başlamıyor.
    private static let debugMixDecks = ["party", "movieClassics", "cities"]

    private static let debugWords = [
        "Kahve molası", "Zoom", "Terfi", "Mesai", "Bordro", "Yazıcı",
        "Toplantı", "Ayşe'nin köpeği", "Müdürün arabası", "Mola",
    ]

    /// Simülatör doğrulaması. Tilt sensörü ve ekran döndürme simülatörde
    /// olmadığı için oyun fazlarına başka türlü girilemiyor.
    ///
    ///   -DeckDetail party      deste detayı sheet'i
    ///   -Mode rapid            oyun modu (varsayılan `classic`)
    ///   -ModeSelect            Mod Seçimi sheet'i
    ///   -Preset party          Tur Ön Ayar sheet'i, verilen deste seçili
    ///   -HowTo                 Nasıl Oynanır slider'ı
    ///   -StartGame a,b         turu başlat (Yatay Çevir ekranı); virgülle Mix
    ///   -SkipRotate            cihaz yatay gelmiş gibi davran
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
        } else if arguments.contains("-Free") {
            SubscriptionStore.shared.debugPremiumOverride = false
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
            setup.teams = [
                Team(name: "Perdeciler", players: ["Metehan", "Ayşe"]),
                Team(name: "Makaracılar", players: ["Elif", "Burak"])
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
            modelContext.insert(
                CustomDeck(
                    name: "Ofis Muhabbeti",
                    languageCode: LocalizationManager.shared.localeCode,
                    words: Array(Self.debugWords.prefix(count))
                )
            )
        }
        if arguments.contains("-Basket") {
            let count = value(after: "-Basket").flatMap(Int.init) ?? 7
            setup.basketWords = Array(Self.debugWords.prefix(count))
        }

        if arguments.contains("-CustomList") {
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
            router.push(.teamSetup)
        } else if let id = value(after: "-DeckDetail") {
            router.openDeckDetail(id)
        } else if arguments.contains("-ModeSelect") {
            router.beginSetup()
        } else if let ids = value(after: "-Preset") {
            setup.select(all: deckIDs(ids))
            router.setupStep = .preset
        } else if arguments.contains("-HowTo") {
            router.openHowToPlay(for: setup.mode)
        } else if let ids = value(after: "-StartGame") {
            setup.select(all: deckIDs(ids))
            startGame()
            if arguments.contains("-SkipRotate") {
                liveGame?.deviceBecameLandscape()
            }
        } else if let id = value(after: "-SelectDeck") {
            setup.select(only: id)
        }
    }
    #endif

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .mix:
            MixSetupView { router.setupStep = .preset }
        case .customList:
            CustomDeckListView()
        case .customEditor(let id):
            CustomDeckEditorView(deckID: id.flatMap(UUID.init(uuidString:)))
        case .wordBasket:
            WordBasketView { router.setupStep = .preset }
        case .teamSetup:
            TeamSetupView { router.setupStep = .preset }
        case .archive:
            PlaceholderScreen(titleKey: "archive.title", packageNote: "P15")
        case .archivePlayer(let id):
            PlaceholderScreen(titleKey: "archive.player.title", packageNote: "P15", detail: id)
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
            Button {
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.accentBrass)
                    .frame(width: 40, height: 40)
            }
            .padding(.leading, 10)
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

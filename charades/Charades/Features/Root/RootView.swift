import StoreKit
import SwiftData
import SwiftUI


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


    #if DEBUG

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


        .sheet(isPresented: isShowingSetup) { setupSheet }


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


                    .transition(.identity)
            }
        }
    }


    private func finishReveal() {
        isRevealing = false
        startFirstRunIfNeeded()
    }


    private func startFirstRunIfNeeded() {
        guard !settings.onboardingDone, !isShowingOnboarding else { return }
        isShowingOnboarding = true
    }


    private func offerOnboardingPaywall() {
        guard settings.onboardingDone, !settings.paywallSeen, !subscriptions.isPremium else { return }
        router.openPaywall(.vipButton, variant: .onboarding)
    }


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


    private var promptGateID: String {
        "\(isHomeIdle)-\(settings.notificationPrompted)-\(canOfferRateUs)"
    }


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

        }

        guard canOfferRateUs, prompts.claim(.rateUs) else { return }
        settings.markRateUsPrompted()
        requestReview()
    }


    private var isShowingSetup: Binding<Bool> {
        Binding(
            get: { router.setupStep != nil },
            set: { if !$0 { router.closeSetup() } }
        )
    }


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
                .presentationDetents([.large])

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


    private func openSideSetup(for mode: GameMode) {

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

                        .onSwipeBack { router.pop() }
                }
                .onAppear {
                    #if DEBUG
                    applyDebugArguments()


                    if !isRevealing { startFirstRunIfNeeded() }
                    #endif
                }
        }
        .tint(AppColors.accentAmber)


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


        .overlay(alignment: .bottom) {
            LockedNotice(text: router.lockedNotice) { router.lockedNotice = nil }
        }
    }


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

        PaywallView(context: context, variant: router.paywallVariant) { router.paywall = nil }
            .environment(LocalizationManager.shared)
            .environment(AppSettingsStore.shared)
            .environment(SubscriptionStore.shared)
            .localizedLayout()
    }


    private func startGame() {
        let settings = AppSettingsStore.shared

        let canTilt = MotionService.shared.isAvailable && !settings.prefersTouchAnswers

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

    private static let debugMixDecks = ["party", "movieClassics", "cities"]

    private static let debugWords = [
        "Kahve molası", "Zoom", "Terfi", "Mesai", "Bordro", "Yazıcı",
        "Toplantı", "Ayşe'nin köpeği", "Müdürün arabası", "Mola",
    ]


    private static func debugSeedWords(_ count: Int) -> [String] {
        let language = LocalizationManager.shared.localeCode
        let words = CardBank.shared
            .cards(in: DeckCatalog.freeDeckID)
            .prefix(count)
            .map { $0.text(for: language) }
        return words.isEmpty ? Array(debugWords.prefix(count)) : Array(words)
    }


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


        func deckIDs(_ raw: String) -> [String] {
            raw.split(separator: ",").map(String.init)
        }

        func savedMixCount() -> Int {
            (try? modelContext.fetchCount(FetchDescriptor<SavedMix>())) ?? 0
        }

        func customDeckCount() -> Int {
            (try? modelContext.fetchCount(FetchDescriptor<CustomDeck>())) ?? 0
        }


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

        if let code = value(after: "-Lang") {
            LocalizationManager.shared.setLanguage(code)
        }
        if arguments.contains("-MuteSound") {
            AppSettingsStore.shared.soundEnabled = false
        }


        if arguments.contains("-FakeReplay") {
            SubscriptionStore.shared.debugPremiumOverride = true
            AppSettingsStore.shared.replayEnabled = true
        }


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


    var deckBinding: Binding<DeckDef?> {
        Binding<DeckDef?>(
            get: { wrappedValue.flatMap(DeckCatalog.deck) },
            set: { wrappedValue = $0?.id }
        )
    }
}

import SwiftData
import SwiftUI


struct DecksHomeView: View {


    var onPlay: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppSettingsStore.self) private var settings
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(AppRouter.self) private var router
    @Environment(GameSetup.self) private var setup
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass


    @Query(sort: \SavedMix.sortIndex) private var savedMixes: [SavedMix]


    @Query(sort: \CustomDeck.sortIndex) private var customDecks: [CustomDeck]


    private var listedCustomDecks: [CustomDeck] {
        customDecks.filter(\.hasListableContent)
    }

    @State private var filter: DeckFilter = .all

    @State private var archiveCount = 0

    private var dailyFreeDeckID: String? { DeckCatalog.dailyFreeDeckID() }


    private var showsLapseNotice: Bool {
        subscriptions.didLapse && !settings.lapseNoticeShown
    }

    var body: some View {
        ZStack {
            VelvetBackground(showsLightLeak: true)

            ScrollView {
                VStack(spacing: 0) {
                    if showsLapseNotice {
                        LapseNoticeCard(
                            onSeeTicket: {
                                settings.markLapseNoticeShown()
                                router.openPaywall(.vipButton)
                            },
                            onDismiss: settings.markLapseNoticeShown
                        )
                        .padding(.horizontal, 18)
                        .padding(.top, 15)
                    }

                    if !subscriptions.isPremium,
                       let dailyFreeDeckID,
                       let deck = DeckCatalog.deck(dailyFreeDeckID) {
                        NowShowingStrip(deck: deck) { router.openDeckDetail(deck.id) }
                            .padding(.horizontal, 18)
                            .padding(.top, 15)
                            .onAppear { Analytics.dailyFreeDeckView(deckID: deck.id) }
                    }

                    sectionRow

                    FeaturedRow(
                        isWordBasketLocked: !subscriptions.isPremium,
                        hasCustomDecks: !listedCustomDecks.isEmpty,
                        onMix: { router.push(.mix) },
                        onWordBasket: openWordBasket,
                        onCustomDecks: openCustomDecks
                    )

                    if visibleDecks.isEmpty {
                        emptyState
                    } else {
                        deckGrid
                    }
                }
                .padding(.bottom, 24)
                .readableWidth(AppLayout.gridWidth)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .top, spacing: 0) {
                topBar.readableWidth(AppLayout.gridWidth)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomBar.readableWidth(AppLayout.gridWidth)
            }
        }


        .onChange(of: subscriptions.isPremium, initial: true) { _, isPremium in
            settings.syncLapseNotice(isPremium: isPremium)
        }


        .task(id: router.path) { archiveCount = ReplayStore.reelCount() }
    }


    private var topBar: some View {
        VStack(spacing: 12) {
            HeaderBar(
                archiveCount: archiveCount,
                isPremium: subscriptions.isPremium,
                onTapVIP: { router.openPaywall(.vipButton) },
                onTapTeams: { router.push(.teamSetup(resumesModeSelect: false)) },
                onTapArchive: {
                    Analytics.replayArchiveOpen(entry: .header, reelCount: archiveCount)
                    router.push(.archive)
                },
                onTapSettings: { router.isShowingSettings = true }
            )

            FilterChipRow(
                selection: $filter,
                favoriteCount: settings.favoriteDeckIDs.count
            )
        }
        .padding(.bottom, 10)
        .background {
            AppColors.bgVelvetDeep.opacity(0.98)
                .ignoresSafeArea(edges: .top)
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if setup.hasSelection {
            PlayBar(
                deckCount: setup.selectedDeckIDs.count,
                cardCount: setup.selectedCardCount,
                isMix: setup.isMix,
                isPremium: subscriptions.isPremium,
                isPlayEnabled: isPlayEnabled,
                onPlay: play
            )
        }
    }


    private var isPlayEnabled: Bool {
        setup.selectedDeckIDs.allSatisfy { DeckCatalog.contentReadyIDs.contains($0) }
    }


    private func isOffMode(_ deck: DeckDef) -> Bool {
        !deck.isRecommended(inActOutMode: setup.mode == .actOut)
    }

    private func play() {

        if setup.isMix, !subscriptions.isPremium {
            router.openPaywall(.mix)
            return
        }

        if !subscriptions.isPremium,
           let lockedID = setup.selectedDeckIDs.first(where: {
               DeckCatalog.deck($0)?.isLocked(
                   isPremium: false,
                   dailyFreeDeckID: dailyFreeDeckID
               ) == true
           })
        {
            Haptics.lockedWall()
            router.openPaywall(.lockedDeck(lockedID))
            return
        }
        if setup.isMix {
            setup.mode = .mix
        } else if setup.mode == .mix || !setup.mode.needsDeckSelection {


            setup.mode = .classic
        }
        Haptics.primaryButton()
        onPlay()
    }


    private func playSavedMix(_ mix: SavedMix) {
        setup.select(all: mix.deckIDs)
        setup.mode = .mix

        guard mix.isPlayable else {
            router.push(.mix)
            return
        }
        guard subscriptions.isPremium else {
            Haptics.lockedWall()
            router.openPaywall(.mix)
            return
        }
        Haptics.primaryButton()
        router.setupStep = .mode
    }

    private func openWordBasket() {
        guard subscriptions.isPremium else {
            Haptics.lockedWall()
            router.openPaywall(.lockedMode(GameMode.ownWords.id))
            return
        }
        setup.mode = .ownWords
        router.push(.wordBasket)
    }


    private func openCustomDecks() {
        let empties = customDecks.filter { !$0.hasListableContent }
        if !empties.isEmpty {
            for draft in empties { modelContext.delete(draft) }
            modelContext.persistCustomDecks()
        }

        if listedCustomDecks.isEmpty {
            router.push(.customEditor(nil))
        } else {
            router.push(.customList)
        }
    }


    private func playCustomDeck(_ deck: CustomDeck) {
        guard subscriptions.isPremium else {
            Haptics.lockedWall()
            router.openPaywall(.customDeck)
            return
        }


        guard deck.canPlay else {
            Haptics.stepperLimit()
            router.push(.customEditor(deck.uuid.uuidString))
            return
        }
        Haptics.primaryButton()
        setup.select(custom: deck.uuid)


        setup.mode = .classic
        router.beginSetup()
    }

    private func editSavedMix(_ mix: SavedMix) {
        setup.select(all: mix.deckIDs)
        setup.mode = .mix
        router.push(.mix)
    }


    private var sectionRow: some View {
        HStack(spacing: 10) {
            Text(l10n.t(filter == .all ? "decks.mine" : filter.titleKey))
                .font(AppFont.display(16, weight: .semibold))
                .appTracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textCream)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            gridToggle
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }


    private var gridToggle: some View {
        Button {
            Haptics.selection()
            settings.gridColumns = settings.gridColumns == 2 ? 3 : 2
        } label: {
            Image(systemName: settings.gridColumns == 2 ? "square.grid.2x2.fill" : "square.grid.3x3.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppColors.accentGold)
                .frame(width: 40, height: 34)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.surfaceCardRaised, AppColors.surfaceCard],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(AppColors.accentGold.opacity(0.5), lineWidth: 1.15)
                        }
                }
                .tapTarget()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(l10n.t("decks.gridToggle"))
    }

    private var deckGrid: some View {
        let columns = AppLayout.isRegularWidth(horizontalSizeClass)
            ? max(settings.gridColumns + 1, 4)
            : settings.gridColumns

        return LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: 12),
                count: columns
            ),
            spacing: 12
        ) {


            if filter == .all {
                ForEach(listedCustomDecks, id: \.uuid) { deck in
                    Button { playCustomDeck(deck) } label: {
                        CustomDeckCard(deck: deck, isLocked: !subscriptions.isPremium)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(l10n.t("customDeck.edit"), systemImage: "square.and.pencil") {
                            router.push(.customEditor(deck.uuid.uuidString))
                        }
                        Button(l10n.t("common.delete"), systemImage: "trash", role: .destructive) {
                            modelContext.delete(deck)
                            modelContext.persistCustomDecks()
                        }
                    }
                }

                ForEach(savedMixes) { mix in
                    Button { playSavedMix(mix) } label: {


                        SavedMixCard(mix: mix, isLocked: !subscriptions.isPremium)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(l10n.t("mix.saved.edit"), systemImage: "slider.horizontal.3") {
                            editSavedMix(mix)
                        }
                        Button(l10n.t("mix.saved.delete"), systemImage: "trash", role: .destructive) {
                            modelContext.delete(mix)
                            modelContext.persistCustomDecks()
                        }
                    }
                }
            }

            ForEach(visibleDecks) { deck in
                Button {
                    router.openDeckDetail(deck.id)
                } label: {
                    DeckCard(
                        deck: deck,
                        isSelected: setup.isSelected(deck.id),
                        isLocked: false,
                        isDailyFree: false,
                        isOffMode: isOffMode(deck),
                        showsAccessState: false,
                        isFavorite: settings.isFavorite(deck.id)
                    )
                }
                .buttonStyle(.plain)


                .onLongPressGesture(minimumDuration: 0.3) {


                    guard setup.canToggleInMix(deck.id) else {
                        Haptics.stepperLimit()
                        return
                    }
                    let wasSelected = setup.isSelected(deck.id)
                    setup.toggle(deck.id)
                    if wasSelected {
                        Haptics.deckDeselected()
                    } else {
                        Haptics.deckSelected()
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .animation(.easeOut(duration: 0.2), value: settings.gridColumns)
    }


    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "film.stack")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(AppColors.accentBrass)

            Text(l10n.t("decks.empty"))
                .textStyle(.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.vertical, 64)
    }


    private var visibleDecks: [DeckDef] {
        let decks = DeckCatalog.visibleDecks()
        switch filter {
        case .all:
            return DeckCatalog.homeOrderedDecks(isPremium: subscriptions.isPremium)
        case .popular:

            let ranking = Dictionary(
                uniqueKeysWithValues: DeckCatalog.popularDeckIDs.enumerated().map { ($1, $0) }
            )
            return decks.filter { ranking[$0.id] != nil }
                .sorted { (ranking[$0.id] ?? 0) < (ranking[$1.id] ?? 0) }
        case .new:
            return decks.filter { $0.isNew() }.sorted { $0.addedAt > $1.addedAt }
        case .favorites:
            return decks.filter { settings.isFavorite($0.id) }
        case .section(let section):
            return decks.filter { $0.section == section }
        }
    }
}

import SwiftData
import SwiftUI

/// Ana ekran (ekran 4) — 02-ekran-akisi.md §4.
///
/// Kök ekran bu; tab bar yok. Header ve filtre satırı üstte sabit. Alt bölge
/// bağlama göre çalışan bir aksiyon alanı: seçim varsa PlayBar, yoksa tüm
/// dikey alan ızgaraya kalıyor.
struct DecksHomeView: View {
    /// Oyun `NavigationStack`in yerine render edildiği için turu `RootView`
    /// başlatıyor (§02 §5); buradan yalnızca "başlatılabilir" sinyali gidiyor.
    var onPlay: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppSettingsStore.self) private var settings
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(AppRouter.self) private var router
    @Environment(GameSetup.self) private var setup
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// §05 §6: kaydedilmiş karışımlar `BENİM DESTELERİM` bölümünde görünüyor.
    @Query(sort: \SavedMix.sortIndex) private var savedMixes: [SavedMix]

    /// §05 §7: custom desteler de aynı bölümde — kullanıcının kendi yaptığı
    /// deste, katalog destesiyle aynı ızgarada oynanabilir olmalı.
    @Query(sort: \CustomDeck.sortIndex) private var customDecks: [CustomDeck]

    /// Editörün boş taslağı `@Query`'ye düşer; geri dönüşte flaş olmasın diye
    /// yalnızca içerikli desteler listeleniyor.
    private var listedCustomDecks: [CustomDeck] {
        customDecks.filter(\.hasListableContent)
    }

    @State private var filter: DeckFilter = .all
    /// §04 §4.3 giriş noktası 1: header'daki makara; sayısı rozette (0 iken yok).
    @State private var archiveCount = 0

    private var dailyFreeDeckID: String? { DeckCatalog.dailyFreeDeckID() }

    /// §09 §7: yalnızca aboneliği düşen kullanıcıya ve yalnızca bir kez.
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
        // Premium'a dönülünce bilgi kartı sıfırlanıyor; ikinci bir düşüşte
        // kullanıcı yine bir kez bilgilendiriliyor.
        .onChange(of: subscriptions.isPremium, initial: true) { _, isPremium in
            settings.syncLapseNotice(isPremium: isPremium)
        }
        // Arşivden dönüşte kayıt silinmiş olabiliyor; tur sonrası dönüşte de
        // yeni bir makara eklenmiş oluyor.
        .task(id: router.path) { archiveCount = ReplayStore.reelCount() }
    }

    // MARK: Üst sabit alan

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

    /// §10 §4: katalogda tanımlı ama kelime dosyası henüz üretilmemiş deste
    /// kilitli değil **içeriksiz**. `CardBank` boş havuzla tur başlatmıyor,
    /// o yüzden buton da açılmıyor.
    private var isPlayEnabled: Bool {
        setup.selectedDeckIDs.allSatisfy { DeckCatalog.contentReadyIDs.contains($0) }
    }

    /// §05 §1: `Canlandır` seçiliyken `describe` desteler soluklaşıyor —
    /// "Periyodik Tablo" vücut diliyle canlandırılamıyor ve kullanıcı kötü turun
    /// suçunu uygulamaya atıyor.
    private func isOffMode(_ deck: DeckDef) -> Bool {
        !deck.isRecommended(inActOutMode: setup.mode == .actOut)
    }

    private func play() {
        // §09 §9: 2+ deste Mix demek ve Mix premium.
        if setup.isMix, !subscriptions.isPremium {
            router.openPaywall(.mix)
            return
        }
        // Ana ızgarada kilit görünmez; PlayBar'dan çıkışta premium desteyi yakala.
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
            // Tek deste seçiliyken Mix ya da Kendi Kelimelerin kalamaz;
            // önceki turdan taşınan mod burada düşüyor.
            setup.mode = .classic
        }
        Haptics.primaryButton()
        onPlay()
    }

    /// §05 §6: kayıtlı karışımın tek amacı hızlı tekrar oynamak — Mod Seçimi
    /// atlanıyor, mod zaten Mix. Karışımdaki desteler katalogdan düşüp ikinin
    /// altına indiyse oynanamaz; kullanıcı kurulumda tamamlıyor.
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

    /// Destesi yoksa editöre kısayol (§02 boş durum); varsa yönetim listesi.
    /// Listeye uğrayıp hemen "Yeni Deste +" görmek çift kapı gibi duruyordu.
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

    /// Izgaradaki custom deste **oynamak** için; düzenleme uzun basışta ve
    /// `BENİM DESTELERİM` listesinde (§05 §7'nin iki kapısı).
    private func playCustomDeck(_ deck: CustomDeck) {
        guard subscriptions.isPremium else {
            Haptics.lockedWall()
            router.openPaywall(.customDeck)
            return
        }
        // Kelimesi yetmeyen taslak oynanamaz; dokunuş editöre götürüyor ki
        // kullanıcı eksiği tamamlayabilsin.
        guard deck.canPlay else {
            Haptics.stepperLimit()
            router.push(.customEditor(deck.uuid.uuidString))
            return
        }
        Haptics.primaryButton()
        setup.select(custom: deck.uuid)
        // Mod hâlâ önceki turdan Mix ya da Kendi Kelimelerin olabilir; ikisi de
        // custom desteyle bağdaşmıyor, Mod Seçimi baştan soruyor.
        setup.mode = .classic
        router.beginSetup()
    }

    private func editSavedMix(_ mix: SavedMix) {
        setup.select(all: mix.deckIDs)
        setup.mode = .mix
        router.push(.mix)
    }

    // MARK: İçerik

    private var sectionRow: some View {
        HStack {
            Text(l10n.t(filter == .all ? "decks.mine" : filter.titleKey))
                .font(AppFont.ui(10.5, weight: .bold))
                .appTracking(2.4)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.accentGold)

            Spacer()

            gridToggle
        }
        .padding(.horizontal, 18)
        .padding(.top, 19)
        .padding(.bottom, 10)
    }

    /// §4: 2 kolon / 3 kolon anahtarı. İkon o an geçerli düzeni gösteriyor.
    private var gridToggle: some View {
        Button {
            settings.gridColumns = settings.gridColumns == 2 ? 3 : 2
        } label: {
            let side = settings.gridColumns
            Grid(horizontalSpacing: 2.5, verticalSpacing: 2.5) {
                ForEach(0..<side, id: \.self) { _ in
                    GridRow {
                        ForEach(0..<side, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(AppColors.accentBrass)
                                .frame(width: 5, height: 5)
                        }
                    }
                }
            }
            .frame(width: 34, height: 34)
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
            // Karışımlar yalnızca `BENİM DESTELERİM`de: bir filtre seçiliyken
            // ızgara o filtrenin sonucunu göstermeli, karışımın bölümü yok.
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
                        // §09 §7: abonelik düşerse kayıtlı karışımlar silinmiyor,
                        // görünür ve salt-okunur kalıyor.
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
                        cardCount: DeckCardCounts.count(for: deck.id),
                        isOffMode: isOffMode(deck),
                        showsAccessState: false,
                        isFavorite: settings.isFavorite(deck.id)
                    )
                }
                .buttonStyle(.plain)
                // Uzun basış seçimi doğrudan değiştiriyor; kısa dokunuş her
                // zaman detaya gidiyor. İki deste seçip Mix'e girmek isteyen
                // kullanıcı için detay sheet'inden geçmek gereksiz adım.
                .onLongPressGesture(minimumDuration: 0.3) {
                    // Ana ızgarada kilit görünmez; premium kontrolü detay /
                    // OYNA anında. Burada yalnızca karışım tavanı bakılır.
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

    /// §6: filtre sonucu boş → film şeridi ikonu + açıklama.
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

    // MARK: Filtreleme

    private var visibleDecks: [DeckDef] {
        let decks = DeckCatalog.visibleDecks()
        switch filter {
        case .all:
            return DeckCatalog.homeOrderedDecks(isPremium: subscriptions.isPremium)
        case .popular:
            // Sıra Remote Config'ten geliyor; katalog sırası değil o sıra geçerli.
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

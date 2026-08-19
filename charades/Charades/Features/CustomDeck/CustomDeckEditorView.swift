import SwiftData
import SwiftUI


struct CustomDeckEditorView: View {

    let deckID: UUID?

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppRouter.self) private var router
    @Environment(GameSetup.self) private var setup
    @Environment(SubscriptionStore.self) private var subscription
    @Environment(\.modelContext) private var modelContext


    @Query private var decks: [CustomDeck]

    @State private var createdID: UUID?
    @State private var wordDraft = ""
    @State private var showDeleteConfirm = false
    @State private var isPickingCover = false
    @FocusState private var isNamingFocused: Bool

    private var deck: CustomDeck? {
        let id = deckID ?? createdID
        return decks.first { $0.uuid == id }
    }


    private func projectedWordCount(for deck: CustomDeck) -> Int {
        let words = deck.words
        let draft = wordDraft
        let result = WordList.inserting(draft, into: words, limit: CustomDeckLimits.maxWords)
        return result.addedCount > 0 ? result.words.count : deck.wordCount
    }

    var body: some View {
        ZStack {
            VelvetBackground()

            if let deck {
                editor(deck)
            }
        }
        .dismissKeyboardOnTap()
        .onAppear(perform: createIfNeeded)


        .onDisappear(perform: discardIfEmpty)
        .alert(
            l10n.t("customDeck.delete.title"),
            isPresented: $showDeleteConfirm
        ) {
            Button(l10n.t("common.cancel"), role: .cancel) {}
            Button(l10n.t("customDeck.delete.confirm"), role: .destructive, action: deleteDeck)
        } message: {
            Text(l10n.t("customDeck.delete.body", ["name": displayName(deck)]))
        }
    }

    private func editor(_ deck: CustomDeck) -> some View {
        @Bindable var deck = deck

        return VStack(spacing: 0) {
            navBar(deck)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    identity(deck)

                    field(label: l10n.t("customDeck.field.words")) {
                        WordListSection(
                            words: wordsBinding(deck),
                            draft: $wordDraft
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            footer(deck)
        }
        .sheet(isPresented: $isPickingCover) {
            CoverPickerSheet(
                selection: Binding(
                    get: { deck.cover },
                    set: { newCover in
                        deck.coverTemplate = newCover.rawValue
                        deck.coverImageData = nil
                        deck.updatedAt = .now
                        modelContext.persistCustomDecks()
                    }
                ),
                imageData: Binding(
                    get: { deck.coverImageData },
                    set: { data in
                        deck.coverImageData = data
                        deck.updatedAt = .now
                        modelContext.persistCustomDecks()
                    }
                ),
                onClose: { isPickingCover = false }
            )
            .environment(l10n)
            .environment(subscription)
            .presentationDetents([.medium, .large])
        }
    }


    private func navBar(_ deck: CustomDeck) -> some View {
        HStack(spacing: 0) {
            BackNavButton(accessibilityLabel: l10n.t("common.back")) {
                finishEditing(playAfter: false)
            }

            VStack(spacing: 2) {
                Text(deck.name.isEmpty ? l10n.t("customDeck.defaultName") : deck.name)
                    .font(AppFont.display(19, weight: .bold))
                    .appTracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textCream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(l10n.t("customDeck.autosave"))
                    .font(AppFont.ui(12))
                    .foregroundStyle(AppColors.textMuted)
            }
            .frame(maxWidth: .infinity)

            Button {
                Haptics.secondaryButton()
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.accentGold)
                    .frame(width: BackNavButton.hitSide, height: BackNavButton.hitSide)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.t("common.delete"))
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
    }

    private func displayName(_ deck: CustomDeck?) -> String {
        let name = deck?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? l10n.t("customDeck.defaultName") : name
    }


    private func identity(_ deck: CustomDeck) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Button {
                Haptics.secondaryButton()
                isNamingFocused = false
                isPickingCover = true
            } label: {
                CustomDeckCard(deck: deck, isLocked: false)
                    .frame(width: 118)
                    .id("preview-\(deck.coverTemplate)-\(deck.coverImageData?.count ?? 0)")
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "paintbrush.pointed.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppColors.textOnAmber)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(AppColors.accentAmber))
                            .overlay {
                                Circle().strokeBorder(AppColors.bgFilmBlack.opacity(0.35), lineWidth: 1)
                            }
                            .offset(x: 6, y: 6)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.t("customDeck.field.cover"))

            nameField(deck)
        }
    }

    private func field(label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("◆ \(label)")
                .font(AppFont.ui(12, weight: .semibold))
                .appTracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.accentGold)

            content()
        }
    }

    private func nameField(_ deck: CustomDeck) -> some View {
        @Bindable var deck = deck

        return field(label: l10n.t("customDeck.field.name")) {
            TextField(l10n.t("customDeck.name.placeholder"), text: $deck.name)
                .font(AppFont.display(18, weight: .medium))
                .foregroundStyle(AppColors.textCream)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .focused($isNamingFocused)
                .onChange(of: deck.name) { _, new in
                    if new.count > CustomDeckLimits.maxNameLength {
                        deck.name = String(new.prefix(CustomDeckLimits.maxNameLength))
                        Haptics.stepperLimit()
                    }
                    deck.updatedAt = .now
                }
                .padding(.horizontal, 14)
                .frame(height: 54)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.bgFilmBlack.opacity(0.66))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12).strokeBorder(
                                isNamingFocused
                                    ? AppColors.accentAmber
                                    : AppColors.accentGold.opacity(0.34),
                                lineWidth: 1
                            )
                        }
                }
        }
    }

    private func wordsBinding(_ deck: CustomDeck) -> Binding<[String]> {
        Binding(
            get: { deck.words },
            set: {
                deck.replaceWords($0)
                modelContext.persistCustomDecks()
            }
        )
    }


    private func footer(_ deck: CustomDeck) -> some View {
        VStack(spacing: 8) {
            if projectedWordCount(for: deck) < CustomDeckLimits.minWordsToPlay {
                Text(l10n.t("customDeck.needsMore", count: CustomDeckLimits.minWordsToPlay))
                    .font(AppFont.ui(13))
                    .foregroundStyle(AppColors.stateWarning)
            }

            Button {
                finishEditing(playAfter: true)
            } label: {
                Text(l10n.t("customDeck.saveAndPlay"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .buttonStyle(MarqueeButtonStyle())
            .disabled(projectedWordCount(for: deck) < CustomDeckLimits.minWordsToPlay)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background {
            LinearGradient(
                colors: [
                    AppColors.surfaceCard.opacity(0.86),
                    AppColors.bgFilmBlack.opacity(0.99),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(AppColors.accentGold.opacity(0.34))
                    .frame(height: 1)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }


    private func createIfNeeded() {
        guard deckID == nil, createdID == nil else { return }
        let limit = CustomDeckLimits.maxDeckCount(isPremium: subscription.isPremium)
        guard decks.count < limit else {
            Haptics.lockedWall()
            router.openPaywall(.customDeck)
            router.pop()
            return
        }

        let deck = CustomDeck(
            name: "",
            languageCode: l10n.localeCode,
            sortIndex: (decks.map(\.sortIndex).max() ?? -1) + 1
        )
        modelContext.insert(deck)
        modelContext.persistCustomDecks()
        createdID = deck.uuid
        Analytics.customDeckCreate(wordCount: 0)
    }

    private func discardIfEmpty() {
        guard let deck else { return }


        _ = commitPendingDraft(into: deck, trackAnalytics: false)
        modelContext.persistCustomDecks()
        guard !deck.hasListableContent else { return }
        modelContext.delete(deck)
        modelContext.persistCustomDecks()
    }

    private func deleteDeck() {
        guard let deck else { return }
        Haptics.deckDeselected()
        modelContext.delete(deck)
        modelContext.persistCustomDecks()
        router.pop()
    }


    private func finishEditing(playAfter: Bool) {
        guard let deck else {
            router.pop()
            return
        }

        _ = commitPendingDraft(into: deck, trackAnalytics: true)
        modelContext.persistCustomDecks()

        if playAfter {


            guard subscription.isPremium else {
                Haptics.lockedWall()
                router.openPaywall(.customDeck)
                return
            }
            guard deck.canPlay else {
                Haptics.stepperLimit()
                return
            }
            Haptics.primaryButton()
            setup.select(custom: deck.uuid)
            router.popToRoot()
            router.beginSetup()
            return
        }


        let shouldKeep = deck.hasListableContent
        if !shouldKeep {
            modelContext.delete(deck)
            modelContext.persistCustomDecks()
            router.pop()
            return
        }

        leaveEditor(saved: deck)
    }

    @discardableResult
    private func commitPendingDraft(into deck: CustomDeck, trackAnalytics: Bool) -> WordList.Insertion {
        var words = deck.words
        let flush = WordDraft.flush(draft: &wordDraft, into: &words)
        if flush.addedCount > 0 {
            deck.replaceWords(words)
            if trackAnalytics {
                Analytics.customDeckWordAdd(wordCount: flush.addedCount)
            }
        }
        return flush
    }


    private func leaveEditor(saved deck: CustomDeck) {
        if deckID == nil, deck.hasListableContent {
            router.path = [.customList]
        } else {
            router.pop()
        }
    }
}

import SwiftData
import SwiftUI


struct MixSetupView: View {

    var onContinue: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppRouter.self) private var router
    @Environment(GameSetup.self) private var setup
    @Environment(AppSettingsStore.self) private var settings
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \SavedMix.sortIndex) private var savedMixes: [SavedMix]

    @State private var isNamingMix = false
    @State private var draftName = ""

    private var dailyFreeDeckID: String? { DeckCatalog.dailyFreeDeckID() }

    private var selectionCount: Int { setup.selectedDeckIDs.count }


    private var hasContent: Bool {
        setup.selectedDeckIDs.allSatisfy { DeckCatalog.contentReadyIDs.contains($0) }
    }

    private var canPlay: Bool { setup.isMixReady && hasContent }

    var body: some View {
        ZStack {
            VelvetBackground()

            VStack(spacing: 0) {
                navBar

                ScrollView {
                    VStack(spacing: 0) {
                        mixBar

                        if !savedMixes.isEmpty {
                            SavedMixesRow(
                                mixes: savedMixes,
                                appliedIDs: setup.selectedDeckIDs,
                                onApply: apply
                            )
                            .padding(.top, 16)
                        }

                        sectionRow
                        deckGrid
                    }
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)

                footer
            }
        }
        .alert(l10n.t("mix.save.title"), isPresented: $isNamingMix) {
            TextField(l10n.t("mix.save.placeholder"), text: $draftName)
                .textInputAutocapitalization(.words)
            Button(l10n.t("common.cancel"), role: .cancel) {}
            Button(l10n.t("mix.save.confirm"), action: saveMix)
        } message: {
            Text(l10n.t("mix.save.body", count: selectionCount))
        }
    }


    private var navBar: some View {
        HStack(spacing: 0) {
            BackNavButton(accessibilityLabel: l10n.t("common.back")) {
                router.pop()
            }

            VStack(spacing: 2) {
                Text(l10n.t("featured.mix"))
                    .font(AppFont.display(19, weight: .bold))
                    .appTracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textCream)

                Text(l10n.t("mix.subtitle"))
                    .font(AppFont.ui(10.5))
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)

            saveButton
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
    }


    private var saveButton: some View {
        Button {
            Haptics.secondaryButton()
            draftName = suggestedName
            isNamingMix = true
        } label: {
            Image(systemName: isSelectionSaved ? "bookmark.fill" : "bookmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(canSave ? AppColors.accentGold : AppColors.stateLocked)
                .frame(width: BackNavButton.hitSide, height: BackNavButton.hitSide)
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .accessibilityLabel(l10n.t("mix.save.title"))
    }

    private var isSelectionSaved: Bool {
        savedMixes.contains { $0.deckIDs == setup.selectedDeckIDs }
    }

    private var canSave: Bool {
        setup.isMixReady && !isSelectionSaved && savedMixes.count < MixLimits.maxSaved
    }


    private var suggestedName: String {
        guard let first = setup.selectedDecks.first else { return "" }
        return l10n.t("mix.save.suggestion", ["deck": l10n.t(first.titleKey)])
    }


    private var mixBar: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(l10n.t("mix.selected", count: selectionCount))
                    .font(AppFont.display(12.5, weight: .semibold))
                    .appTracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textCream)

                Spacer(minLength: 8)

                Text(l10n.t("playbar.cards", count: setup.selectedCardCount))
                    .font(AppFont.display(13, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(AppColors.accentAmber)
            }

            MixMeter(decks: setup.selectedDecks)

            Text(l10n.t("mix.rule"))
                .font(AppFont.ui(9.5))
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.accentTeal.opacity(0.24),
                            AppColors.surfaceCard.opacity(0.8),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppColors.accentTeal.opacity(0.55), lineWidth: 1)
                }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .animation(.easeOut(duration: 0.22), value: selectionCount)
    }


    private var sectionRow: some View {
        Text(l10n.t("mix.allDecks"))
            .font(AppFont.ui(10.5, weight: .bold))
            .appTracking(2.4)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.accentGold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 10)
    }


    private var deckGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 3),
            spacing: 9
        ) {
            ForEach(DeckCatalog.visibleDecks()) { deck in
                let isLocked = deck.isLocked(
                    isPremium: subscriptions.isPremium,
                    dailyFreeDeckID: dailyFreeDeckID
                )
                Button {
                    toggle(deck, isLocked: isLocked)
                } label: {
                    DeckCard(
                        deck: deck,
                        isSelected: setup.isSelected(deck.id),
                        isLocked: isLocked,
                        isDailyFree: deck.id == dailyFreeDeckID && !deck.isFree,
                        selectionOrder: setup.mixOrder(of: deck.id)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }


    private var footer: some View {
        VStack(spacing: 7) {
            if let hint = footerHint {
                Text(hint)
                    .font(AppFont.ui(11))
                    .foregroundStyle(AppColors.stateWarning)
                    .multilineTextAlignment(.center)
            }

            Button(l10n.t("mix.play"), action: play)
                .buttonStyle(MarqueeButtonStyle())
                .disabled(!canPlay)
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


    private var footerHint: String? {
        if selectionCount < MixLimits.deckRange.lowerBound { return l10n.t("mix.hint.tooFew") }
        if !hasContent { return l10n.t("playbar.noContent") }
        return nil
    }


    private func toggle(_ deck: DeckDef, isLocked: Bool) {
        guard !isLocked else {
            Haptics.lockedWall()
            router.openPaywall(.lockedDeck(deck.id))
            return
        }
        guard setup.canToggleInMix(deck.id) else {


            Haptics.stepperLimit()
            return
        }
        if setup.isSelected(deck.id) {
            Haptics.deckDeselected()
        } else {
            Haptics.deckSelected()
        }
        setup.toggle(deck.id)
    }

    private func apply(_ mix: SavedMix) {
        Haptics.deckSelected()
        setup.select(all: mix.deckIDs)
    }

    private func saveMix() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? suggestedName : trimmed

        let topIndex = (savedMixes.map(\.sortIndex).min() ?? 0) - 1
        modelContext.insert(
            SavedMix(name: name, deckIDs: setup.selectedDeckIDs, sortIndex: topIndex)
        )
        modelContext.persistCustomDecks()
        Haptics.purchaseSucceeded()
    }

    private func play() {


        guard subscriptions.isPremium else {
            Haptics.lockedWall()
            router.openPaywall(.mix)
            return
        }
        Haptics.primaryButton()
        setup.mode = .mix
        onContinue()
    }
}


private struct MixMeter: View {
    let decks: [DeckDef]

    var body: some View {
        GeometryReader { geometry in
            let fill = geometry.size.width
                * CGFloat(decks.count) / CGFloat(MixLimits.deckRange.upperBound)

            HStack(spacing: 1) {
                ForEach(decks) { deck in
                    Rectangle().fill(deck.section.meterTone)
                }
            }
            .frame(width: max(0, fill), alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 5)
        .background(AppColors.bgFilmBlack.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .animation(.easeOut(duration: 0.22), value: decks.count)
    }
}

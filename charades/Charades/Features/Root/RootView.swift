import SwiftUI
import SwiftData

/// Paket 2 veri katmanı demosu. Gerçek navigasyon kabuğu P3'te bunun yerine geçecek.
struct RootView: View {
    @Bindable private var l10n = LocalizationManager.shared
    @Query(sort: \CustomDeck.sortIndex) private var customDecks: [CustomDeck]
    @Environment(\.modelContext) private var modelContext

    private var dailyFreeID: String? { DeckCatalog.dailyFreeDeckID() }
    private var newCount: Int { DeckCatalog.v1.filter { $0.isNew() }.count }

    var body: some View {
        ZStack {
            VelvetBackground(showsCurtain: false, showsLightLeak: true)

            ScrollView {
                VStack(spacing: 22) {
                    header
                    catalogSummary
                    filterStrip
                    sampleDecks
                    customDeckDemo
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
        }
    }

    // MARK: Üst

    private var header: some View {
        VStack(spacing: 8) {
            Text(l10n.t("app.name"))
                .textStyle(.marquee)
                .foregroundStyle(AppColors.surfacePoster)
                .shadow(color: AppColors.accentAmber.opacity(0.45), radius: 16)

            Text(l10n.t("data.catalog.title"))
                .textStyle(.sectionLabel)
                .foregroundStyle(AppColors.accentGold)
        }
        .padding(.bottom, 4)
    }

    private var catalogSummary: some View {
        DemoCard {
            Text(
                l10n.t(
                    "data.catalog.summary",
                    [
                        "v1": "\(DeckCatalog.v1.count)",
                        "total": "\(DeckCatalog.all.count)",
                        "ready": "\(DeckCatalog.contentReadyIDs.count)",
                    ]
                )
            )
            .textStyle(.bodyStrong)
            .foregroundStyle(AppColors.textCream)

            if let dailyFreeID, let deck = DeckCatalog.deck(dailyFreeID) {
                Text(l10n.t("data.dailyFree", ["title": l10n.t(deck.titleKey)]))
                    .textStyle(.caption)
                    .foregroundStyle(AppColors.accentAmber)
            }

            Text(l10n.t("data.newChip", ["count": "\(newCount)"]))
                .textStyle(.caption)
                .foregroundStyle(AppColors.textSecondary)

            sectionCounts
        }
    }

    private var sectionCounts: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(DeckSection.allCases) { section in
                let count = DeckCatalog.decks(in: section).count
                HStack {
                    Circle()
                        .fill(section.dominantTone)
                        .frame(width: 8, height: 8)
                    Text(l10n.t(section.titleKey))
                        .textStyle(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Text("\(count)")
                        .textStyle(.caption)
                        .foregroundStyle(AppColors.textMuted)
                }
            }
        }
        .padding(.top, 6)
    }

    // MARK: Filtre chip'leri

    private var filterStrip: some View {
        DemoCard {
            Text(l10n.t("filter.all"))
                .textStyle(.sectionLabel)
                .foregroundStyle(AppColors.accentGold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DeckFilter.standardOrder) { filter in
                        Text(l10n.t(filter.titleKey))
                            .textStyle(.sectionLabel)
                            .foregroundStyle(
                                filter == .all ? AppColors.textOnAmber : AppColors.textCream
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background {
                                Capsule()
                                    .fill(filter == .all ? AppColors.accentAmber : AppColors.surfaceCardRaised)
                                    .overlay {
                                        Capsule()
                                            .strokeBorder(AppColors.accentGold.opacity(0.35), lineWidth: 1)
                                    }
                            }
                    }
                }
            }
        }
    }

    // MARK: Örnek desteler

    private var sampleDecks: some View {
        DemoCard {
            Text(l10n.t("data.contentReady"))
                .textStyle(.sectionLabel)
                .foregroundStyle(AppColors.accentGold)

            ForEach(Array(DeckCatalog.contentReadyIDs.sorted()), id: \.self) { id in
                if let deck = DeckCatalog.deck(id) {
                    sampleRow(deck)
                }
            }
        }
    }

    private func sampleRow(_ deck: DeckDef) -> some View {
        let cards = CardBank.shared.cards(in: deck.id)
        let locked = deck.isLocked(isPremium: false, dailyFreeDeckID: dailyFreeID)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("REEL \(deck.reelLabel)")
                    .textStyle(.reelLabel)
                    .foregroundStyle(AppColors.accentBrass)

                Text(l10n.t(deck.titleKey))
                    .textStyle(.posterTitle)
                    .foregroundStyle(AppColors.surfacePoster)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                if deck.isFree {
                    badge(l10n.t("deck.free.badge"), AppColors.stateCorrect)
                } else if dailyFreeID == deck.id {
                    badge(l10n.t("deck.dailyFree.badge"), AppColors.accentAmber)
                } else if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppColors.stateLocked)
                }
            }

            Text(l10n.t(deck.descKey))
                .textStyle(.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)

            HStack(spacing: 10) {
                metaPill(deck.playability.rawValue.uppercased())
                metaPill(deck.difficulty.rawValue.uppercased())
                metaPill(deck.localization.rawValue.uppercased())

                Spacer()

                Text(
                    l10n.t(
                        "data.cards.loaded",
                        [
                            "count": "\(cards.count)",
                            "localize": deck.localization.rawValue,
                        ]
                    )
                )
                .textStyle(.caption)
                .foregroundStyle(AppColors.textMuted)
            }

            if !deck.isRecommended(inActOutMode: true) {
                badge(l10n.t("playability.describe.badge"), AppColors.stateWarning)
            }

            if let first = cards.first {
                Text(first.text(for: l10n.localeCode))
                    .textStyle(.body)
                    .foregroundStyle(AppColors.textCream)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: Custom deste

    private var customDeckDemo: some View {
        DemoCard {
            Text(l10n.t("data.customDeck.demo"))
                .textStyle(.sectionLabel)
                .foregroundStyle(AppColors.accentGold)

            Text("\(customDecks.count) / \(CustomDeckLimits.maxDeckCount(isPremium: true))")
                .textStyle(.bodyStrong)
                .foregroundStyle(AppColors.textCream)

            Button {
                seedCustomDeckIfNeeded()
            } label: {
                Text(customDecks.isEmpty ? "Seed demo deck" : "Already seeded")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!customDecks.isEmpty)

            if let deck = customDecks.first {
                Text("\(deck.name) · \(deck.wordCount) · \(l10n.t(deck.cover.titleKey))")
                    .textStyle(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private func seedCustomDeckIfNeeded() {
        guard customDecks.isEmpty else { return }
        let deck = CustomDeck(
            name: "Cuma Gecesi",
            languageCode: l10n.localeCode,
            words: ["Kahve", "Traktör", "Uzaylı", "Pingpong", "Fenerbahçe", "Sinemacı"],
            savedFromBasket: true
        )
        modelContext.insert(deck)
        try? modelContext.save()
    }

    // MARK: Küçük parçalar

    private func badge(_ text: String, _ color: Color) -> some View {
            Text(text)
            .textStyle(.reelLabel)
            .foregroundStyle(AppColors.textOnAmber)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color))
    }

    private func metaPill(_ text: String) -> some View {
        Text(text)
            .textStyle(.reelLabel)
            .foregroundStyle(AppColors.textMuted)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .strokeBorder(AppColors.textMuted.opacity(0.4), lineWidth: 1)
            }
    }
}

private struct DemoCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.surfaceCard.opacity(0.88))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AppColors.accentGold.opacity(0.28), lineWidth: 1)
                }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(CustomDeckStore.makeContainer(inMemory: true))
        .preferredColorScheme(.dark)
}

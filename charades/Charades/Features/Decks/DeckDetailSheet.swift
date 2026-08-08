import SwiftUI

/// Deste Detayı (ekran 5) — `ornek-ekranlar.html` sheet düzeni.
///
/// Üstte `DESTE` başlığı + çarpı; solda küçük afiş, sağda başlık/etiket/açıklama;
/// altta kesik çerçeveli örnek kelimeler ve tam genişlik `OYNA`.
struct DeckDetailSheet: View {
    let deck: DeckDef

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppSettingsStore.self) private var settings
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(AppRouter.self) private var router
    @Environment(GameSetup.self) private var setup
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var sampleWords: [String] = []

    private var dailyFreeID: String? { DeckCatalog.dailyFreeDeckID() }

    private var isLocked: Bool {
        deck.isLocked(isPremium: subscriptions.isPremium, dailyFreeDeckID: dailyFreeID)
    }

    private var isDailyFree: Bool {
        deck.id == dailyFreeID && !deck.isFree
    }

    private var cardCount: Int? { DeckCardCounts.count(for: deck.id) }
    private var hasContent: Bool { DeckCatalog.contentReadyIDs.contains(deck.id) }

    var body: some View {
        SheetScaffold(title: l10n.t("deck.detail.title"), onClose: { dismiss() }) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        hero

                        if !sampleWords.isEmpty {
                            sampleWordSection
                        } else if !hasContent {
                            Text(l10n.t("deck.noContent"))
                                .font(AppFont.ui(12))
                                .foregroundStyle(AppColors.textMuted)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                actions
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.surfaceCard)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                AppColors.surfaceCard
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        // iPad’de large; telefonda %70. Zemin SheetScaffold + SheetEdgeFill
        // ile ekranın altına yapışık kalmalı.
        .presentationDetents(
            AppLayout.isRegularWidth(horizontalSizeClass) ? [.large] : [.fraction(0.7)]
        )
        .presentationContentInteraction(.scrolls)
        .presentationBackground(AppColors.surfaceCard)
        .task(id: deck.id) { loadSampleWords() }
    }

    // MARK: Hero — afiş sol, meta sağ

    private var hero: some View {
        HStack(alignment: .top, spacing: 16) {
            miniPoster
                .frame(width: 128)
                .spotlightSweep(cornerRadius: 14)

            VStack(alignment: .leading, spacing: 0) {
                Text(l10n.t(deck.titleKey))
                    .font(AppFont.accent(26, weight: .black))
                    .foregroundStyle(AppColors.textCream)
                    .fixedSize(horizontal: false, vertical: true)

                tagRow
                    .padding(.top, 10)

                Text(l10n.t(deck.descKey))
                    .font(AppFont.ui(13))
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 11)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// HTML `.dd-poster` — küçük çerçeveli afiş + alt şerit.
    private var miniPoster: some View {
        VStack(spacing: 0) {
            ZStack {
                deck.section.artGradient
                HalftoneTexture(dotSize: 0.7, spacing: 4, color: .black.opacity(0.65))
                    .opacity(0.2)
                Image(deck.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(16)
            }
            .aspectRatio(1, contentMode: .fit)
            .saturation(isLocked ? 0.3 : 1)
            .brightness(isLocked ? -0.18 : 0)

            Text(l10n.t(deck.titleKey))
                .font(AppFont.accent(10.5, weight: .black))
                .foregroundStyle(AppColors.textOnPoster)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .padding(.horizontal, 5)
                .background {
                    LinearGradient(
                        colors: [AppColors.surfacePoster, AppColors.surfaceTicket],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(AppColors.accentGold.opacity(0.3), lineWidth: 1)
        }
        .padding(5)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.surfaceCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AppColors.accentGold, lineWidth: 1.5)
                }
        }
        .shadow(color: .black.opacity(0.55), radius: 10, y: 6)
    }

    private var tagRow: some View {
        FlowLayout(spacing: 5, alignment: .leading) {
            if let cardCount {
                DetailTag(text: l10n.t("deck.cardCount", count: cardCount))
            }
            DetailTag(text: l10n.t(deck.difficulty.titleKey))
            DetailTag(text: l10n.t("deck.reel", ["no": deck.reelLabel]))
            if isDailyFree {
                DetailTag(text: l10n.t("deck.dailyFree.badge"))
            } else if deck.isFree {
                DetailTag(text: l10n.t("deck.free.badge"))
            }
        }
    }

    // MARK: Örnek kelimeler

    private var sampleWordSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("◆  \(l10n.t("deck.sampleWords"))")
                .font(AppFont.ui(10, weight: .bold))
                .appTracking(2.2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.accentGold)

            FlowLayout(spacing: 7, alignment: .leading) {
                ForEach(Array(sampleWords.enumerated()), id: \.offset) { index, word in
                    SampleChip(text: word, isBlurred: index >= 3)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.surfaceCard.opacity(0.8))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            AppColors.accentGold.opacity(0.36),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                        )
                }
        }
    }

    // MARK: CTA

    private var actions: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button(l10n.t(isLocked ? "deck.buyTicket" : "common.play")) {
                    if isLocked {
                        router.openPaywall(.lockedDeck(deck.id))
                    } else {
                        setup.select(only: deck.id)
                        router.beginSetupAfterDeckDetail()
                    }
                }
                .buttonStyle(MarqueeButtonStyle())
                .disabled(!isLocked && !hasContent)

                // §02 §4: ikon buton `FAVORİ` — filtre chip'i en az bir favori
                // varken görünüyor (§09 §9).
                favoriteButton
            }

            if !isLocked {
                Text(l10n.t("deck.play.hint"))
                    .font(AppFont.ui(10))
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var favoriteButton: some View {
        let isFavorite = settings.isFavorite(deck.id)
        return Button {
            Haptics.secondaryButton()
            settings.toggleFavorite(deck.id)
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isFavorite ? AppColors.accentAmber : AppColors.accentBrass)
                .frame(width: 52, height: 52)
                .background {
                    Circle()
                        .fill(AppColors.surfaceCardRaised)
                        .overlay {
                            Circle()
                                .strokeBorder(AppColors.accentGold.opacity(0.4), lineWidth: 1)
                        }
                }
                .frame(width: 52, height: 52)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(l10n.t("deck.favorite"))
        .accessibilityAddTraits(isFavorite ? .isSelected : [])
    }

    /// §4: 6 kelime. Deste dosyası burada lazy yükleniyor — ana ekranda değil.
    private func loadSampleWords() {
        let cards = CardBank.shared.cards(in: deck.id)
        guard !cards.isEmpty else {
            sampleWords = []
            return
        }
        sampleWords = cards.shuffled().prefix(6).map { $0.text(for: l10n.localeCode) }
    }
}

// MARK: - Parçalar

private struct DetailTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppFont.ui(9.5, weight: .semibold))
            .appTracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.accentGold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.accentAmber.opacity(0.14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(AppColors.accentGold.opacity(0.34), lineWidth: 1)
                    }
            }
    }
}

private struct SampleChip: View {
    let text: String
    var isBlurred = false

    var body: some View {
        Text(text)
            .font(AppFont.display(13.5, weight: .medium))
            .appTracking(0.8)
            .foregroundStyle(AppColors.textCream.opacity(isBlurred ? 0.85 : 1))
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: 0x4A3016).opacity(0.5),
                                AppColors.surfaceCard.opacity(0.7),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(AppColors.accentGold.opacity(0.24), lineWidth: 1)
                    }
            }
            .blur(radius: isBlurred ? 3.2 : 0)
            .accessibilityHidden(isBlurred)
    }
}

/// Örnek kelime / etiket satırları değişken uzunlukta sarıyor.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var alignment: HorizontalAlignment = .center

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let widest = subviews.reduce(CGFloat.zero) { max($0, $1.sizeThatFits(.unspecified).width) }
        let width = proposal.width ?? widest
        let rows = layout(subviews: subviews, width: width)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = layout(subviews: subviews, width: bounds.width)
        for row in rows {
            let originX: CGFloat
            switch alignment {
            case .leading:
                originX = bounds.minX
            case .trailing:
                originX = bounds.maxX - row.width
            default:
                originX = bounds.minX + (bounds.width - row.width) / 2
            }
            var x = originX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: bounds.minY + row.y),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
        var y: CGFloat = 0
    }

    private func layout(subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        var y: CGFloat = 0

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width, !current.indices.isEmpty {
                current.y = y
                rows.append(current)
                y += current.height + spacing
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }

        if !current.indices.isEmpty {
            current.y = y
            rows.append(current)
        }
        return rows
    }
}

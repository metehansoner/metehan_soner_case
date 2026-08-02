import SwiftUI

/// Deste Detayı (ekran 5) — `ornek-ekranlar.html` birebir sheet düzeni.
///
/// Sol afiş + sağ meta, kesik çerçeveli örnek kelimeler, altta `.btn-wide`
/// tarzı `OYNA` (ampullü Marquee değil).
struct DeckDetailSheet: View {
    let deck: DeckDef

    @Environment(LocalizationManager.self) private var l10n
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(AppRouter.self) private var router
    @Environment(GameSetup.self) private var setup
    @Environment(\.dismiss) private var dismiss

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
        VStack(spacing: 0) {
            grabber
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                        .padding(.horizontal, 20)

                    if !sampleWords.isEmpty {
                        sampleWordSection
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    } else if !hasContent {
                        Text(l10n.t("deck.noContent"))
                            .font(AppFont.ui(12))
                            .foregroundStyle(AppColors.textMuted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 28)
                            .padding(.top, 20)
                    }

                    actions
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { sheetBackground }
        .presentationDetents([.fraction(0.72)])
        .presentationCornerRadius(28)
        .presentationBackground(.clear)
        .localizedLayout()
        .task(id: deck.id) { loadSampleWords() }
    }

    // MARK: Chrome — `.grabber` / `.sheet-head`

    private var grabber: some View {
        Capsule()
            .fill(AppColors.accentGold.opacity(0.6))
            .frame(width: 38, height: 4)
            .padding(.top, 9)
    }

    private var header: some View {
        HStack {
            Text(l10n.t("deck.detail.title"))
                .font(AppFont.display(21, weight: .bold))
                .appTracking(2.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textCream)

            Spacer(minLength: 0)

            Button {
                Haptics.secondaryButton()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 30, height: 30)
                    .background {
                        Circle()
                            .fill(AppColors.surfaceCardRaised.opacity(0.9))
                            .overlay {
                                Circle().strokeBorder(AppColors.accentGold.opacity(0.45), lineWidth: 1)
                            }
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.t("common.close"))
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 16)
    }

    private var sheetBackground: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: 0x4A1720), location: 0),
                .init(color: AppColors.bgVelvetDeep, location: 0.26),
                .init(color: AppColors.surfaceCard, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.accentGold.opacity(0.5))
                .frame(height: 1)
        }
        .overlay { GrainOverlay() }
        .ignoresSafeArea()
    }

    // MARK: Hero — `.dd-hero`

    private var hero: some View {
        HStack(alignment: .top, spacing: 14) {
            miniPoster
                .frame(width: 104)

            VStack(alignment: .leading, spacing: 0) {
                Text(l10n.t(deck.titleKey))
                    .font(AppFont.accent(22, weight: .black))
                    .foregroundStyle(AppColors.textCream)
                    .lineSpacing(0)
                    .fixedSize(horizontal: false, vertical: true)

                tagRow
                    .padding(.top, 9)

                Text(l10n.t(deck.descKey))
                    .font(AppFont.ui(11.5))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// HTML `.dd-poster` / `.dd-pin` / `.dd-art` (amblem %66).
    private var miniPoster: some View {
        VStack(spacing: 0) {
            ZStack {
                deck.section.artGradient
                HalftoneTexture(dotSize: 0.7, spacing: 4, color: .black.opacity(0.65))
                    .opacity(0.2)
                Image(deck.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(17) // ~%66 of square
            }
            .aspectRatio(1, contentMode: .fit)
            .saturation(isLocked ? 0.3 : 1)
            .brightness(isLocked ? -0.18 : 0)

            Text(l10n.t(deck.titleKey))
                .font(AppFont.accent(9, weight: .black))
                .foregroundStyle(AppColors.textOnPoster)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .padding(.horizontal, 3)
                .background {
                    LinearGradient(
                        colors: [AppColors.surfacePoster, AppColors.surfaceTicket],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(AppColors.accentGold.opacity(0.3), lineWidth: 1)
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.surfaceCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppColors.accentGold, lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.6), radius: 11, y: 8)
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

    // MARK: Örnek kelimeler — `.wordbox` / `.wchip`

    private var sampleWordSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("◆  \(l10n.t("deck.sampleWords"))")
                .font(AppFont.ui(9, weight: .bold))
                .appTracking(2.2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.accentGold)

            FlowLayout(spacing: 6, alignment: .leading) {
                ForEach(Array(sampleWords.enumerated()), id: \.offset) { index, word in
                    SampleChip(text: word, isBlurred: index >= 3)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.surfaceCard.opacity(0.8))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            AppColors.accentGold.opacity(0.36),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                        )
                }
        }
    }

    // MARK: CTA — `.btn-wide` (kapsül/ampul yok)

    private var actions: some View {
        VStack(spacing: 8) {
            Button {
                Haptics.primaryButton()
                if isLocked {
                    router.openPaywall(.lockedDeck(deck.id))
                } else {
                    setup.select(only: deck.id)
                    router.beginSetupAfterDeckDetail()
                }
            } label: {
                Text(l10n.t(isLocked ? "deck.buyTicket" : "common.play"))
                    .font(AppFont.display(17, weight: .bold))
                    .appTracking(3)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textOnAmber)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.accentAmber, AppColors.accentAmberDeep],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(alignment: .top) {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                                    .padding(.bottom, 40)
                                    .clipped()
                            }
                            .shadow(color: AppColors.accentAmber.opacity(0.36), radius: 13)
                    }
            }
            .buttonStyle(.plain)
            .disabled(!isLocked && !hasContent)
            .opacity((!isLocked && !hasContent) ? 0.45 : 1)

            if !isLocked {
                Text(l10n.t("deck.play.hint"))
                    .font(AppFont.ui(10))
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

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
            .font(AppFont.ui(8.5, weight: .semibold))
            .appTracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.accentGold)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(AppColors.accentAmber.opacity(0.14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
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
            .font(AppFont.display(12, weight: .medium))
            .appTracking(0.8)
            .foregroundStyle(AppColors.textCream.opacity(isBlurred ? 0.85 : 1))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
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
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
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

import SwiftUI

/// Deste Detayı (ekran 5) — 02-ekran-akisi.md §4.
///
/// Örnek kelimeler kilitli destede de gösteriliyor: merak uyandırmak paywall'a
/// giden en dürüst yol, kapağın arkasını saklamak değil.
struct DeckDetailSheet: View {
    let deck: DeckDef

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppSettingsStore.self) private var settings
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(AppRouter.self) private var router
    @Environment(GameSetup.self) private var setup
    @Environment(\.dismiss) private var dismiss

    @State private var sampleWords: [String] = []

    private var isLocked: Bool {
        deck.isLocked(
            isPremium: subscriptions.isPremium,
            dailyFreeDeckID: DeckCatalog.dailyFreeDeckID()
        )
    }

    private var cardCount: Int? { DeckCardCounts.count(for: deck.id) }
    private var hasContent: Bool { DeckCatalog.contentReadyIDs.contains(deck.id) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                cover
                header
                metaRow

                if !sampleWords.isEmpty {
                    sampleWordSection
                } else if !hasContent {
                    Text(l10n.t("deck.noContent"))
                        .textStyle(.caption)
                        .foregroundStyle(AppColors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .padding(.top, 22)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) { actions }
        // Arka plan `ZStack` kardeşi değil `background`: blur'lu kapak
        // `scaledToFill` ile kendi piksel boyutunu (512 pt) talep ediyor ve
        // kardeş olduğunda tüm sheet'i o genişliğe çekip içeriği ekranın iki
        // yanından taşırıyordu. `background` ebeveynin boyutunu etkilemiyor.
        .background { background }
        .presentationDetents([.large])
        .presentationCornerRadius(28)
        .presentationBackground(.clear)
        .task(id: deck.id) { loadSampleWords() }
    }

    // MARK: Katmanlar

    /// §4: kart görseli blur'lu arka plan olarak da kullanılıyor.
    private var background: some View {
        ZStack {
            AppColors.screenBackground

            Image(deck.imageName)
                .resizable()
                .scaledToFill()
                .blur(radius: 60, opaque: false)
                .opacity(0.28)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            deck.section.artGradient.opacity(0.35)
            AppColors.vignette
            GrainOverlay()
        }
        .ignoresSafeArea()
    }

    private var cover: some View {
        DeckCard(
            deck: deck,
            isSelected: false,
            isLocked: isLocked,
            isDailyFree: deck.id == DeckCatalog.dailyFreeDeckID() && !deck.isFree,
            cardCount: cardCount,
            isOffMode: !deck.isRecommended(inActOutMode: setup.mode == .actOut)
        )
        .frame(width: 168)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(l10n.t(deck.titleKey))
                .font(AppFont.accent(26, weight: .black))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textCream)

            Text(l10n.t(deck.descKey))
                .textStyle(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, 28)
    }

    /// §4: `130 KART` · `KOLAY` · `4+ OYUNCU`
    private var metaRow: some View {
        HStack(spacing: 10) {
            if let cardCount {
                MetaPill(text: l10n.t("deck.cardCount", ["count": "\(cardCount)"]))
            }
            MetaPill(text: l10n.t(deck.difficulty.titleKey))
            MetaPill(text: l10n.t("deck.minPlayers", ["count": "\(deck.minPlayers)"]))
        }
    }

    private var sampleWordSection: some View {
        VStack(spacing: 10) {
            Text(l10n.t("deck.sampleWords"))
                .textStyle(.sectionLabel)
                .foregroundStyle(AppColors.accentGold)

            FlowLayout(spacing: 8) {
                ForEach(sampleWords, id: \.self) { word in
                    Text(word)
                        .font(AppFont.ui(13, weight: .semibold))
                        .foregroundStyle(AppColors.textOnPoster)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.surfaceTicket)
                                .overlay {
                                    HalftoneTexture(
                                        dotSize: 0.5,
                                        spacing: 3,
                                        color: AppColors.surfaceCard.opacity(0.5)
                                    )
                                    .opacity(0.16)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .rotationEffect(.degrees(-0.6))
                        }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button(l10n.t(isLocked ? "deck.buyTicket" : "common.play")) {
                    if isLocked {
                        router.openPaywall(.lockedDeck(deck.id))
                    } else {
                        // §02 §3 (`F → J`): destenin `OYNA`sı Mod Seçimi'ne
                        // gidiyor, ana ekrana değil.
                        setup.select(only: deck.id)
                        router.beginSetupAfterDeckDetail()
                    }
                }
                .buttonStyle(MarqueeButtonStyle())
                .disabled(!isLocked && !hasContent)

                circleButton(
                    systemImage: settings.isFavorite(deck.id) ? "star.fill" : "star",
                    tint: settings.isFavorite(deck.id) ? AppColors.accentAmber : AppColors.accentBrass,
                    label: l10n.t("deck.favorite")
                ) {
                    settings.toggleFavorite(deck.id)
                }

                // §02 ekran 9: slider mod başına bir kez otomatik açılıyor,
                // sonrasında yalnızca buradan ve duraklat menüsünden.
                circleButton(
                    systemImage: "questionmark",
                    tint: AppColors.accentBrass,
                    label: l10n.t("howToPlay.title")
                ) {
                    router.openHowToPlayAfterDeckDetail(for: setup.mode)
                }
            }

            Button(l10n.t(setup.isSelected(deck.id) ? "deck.removeFromMix" : "deck.addToMix")) {
                setup.toggle(deck.id)
                dismiss()
            }
            .buttonStyle(SecondaryButtonStyle())
            // §05 §6: karışım 8 destede tavan yapıyor; sınır her kapıda geçerli.
            .disabled(isLocked || !setup.canToggleInMix(deck.id))
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background {
            LinearGradient(
                colors: [AppColors.bgFilmBlack.opacity(0), AppColors.bgFilmBlack.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func circleButton(
        systemImage: String,
        tint: Color,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.secondaryButton()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 52, height: 52)
                .background {
                    Circle()
                        .fill(AppColors.surfaceCardRaised)
                        .overlay { Circle().strokeBorder(AppColors.accentGold, lineWidth: 1.5) }
                }
        }
        .buttonStyle(.plain)
        .layoutPriority(1)
        .accessibilityLabel(label)
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

private struct MetaPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppFont.ui(10, weight: .bold))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(AppColors.surfaceCard.opacity(0.7))
                    .overlay {
                        Capsule().strokeBorder(AppColors.accentGold.opacity(0.35), lineWidth: 1)
                    }
            }
    }
}

/// Örnek kelime etiketleri değişken uzunlukta ve 25 dilde farklı sarıyor;
/// sabit kolonlu ızgara ya taşırıyor ya boşluk bırakıyor.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // Dikey `ScrollView` içeriğin ideal boyutunu önce **genişliksiz** bir
        // öneriyle soruyor. Burada `.infinity` dönmek sheet'in tamamını ekrandan
        // taşırıyordu: ızgara ortalanıp iki yandan kırpılıyor, alt buton şeridi
        // de onunla birlikte genişliyordu. Belirsiz öneride en geniş etiket
        // kadar yer isteniyor; gerçek yerleşimde kapsayıcının genişliği zaten
        // geliyor ve satırlar ona göre sarıyor.
        let widest = subviews.reduce(CGFloat.zero) { max($0, $1.sizeThatFits(.unspecified).width) }
        let width = proposal.width ?? widest
        let rows = layout(subviews: subviews, width: width)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = layout(subviews: subviews, width: bounds.width)
        for row in rows {
            var x = bounds.minX + (bounds.width - row.width) / 2
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

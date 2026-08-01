import SwiftData
import SwiftUI

/// Custom Deste Editörü (ekran 8) — 05-desteler-ve-kategoriler.md §7.
///
/// Alanlar doğrudan SwiftData nesnesine yazıyor: mockup'taki "otomatik
/// kaydedilir" alt başlığı bu. Yerel bir kopya tutup `KAYDET`te yazsaydık,
/// 40 kelime girip uygulamayı arka plana atan kullanıcı hepsini kaybederdi.
/// `KAYDET` bu yüzden bir yazma değil, "bitirdim" düğmesi.
struct CustomDeckEditorView: View {
    /// `nil`: listeye uğramadan açılan yeni deste (Öne Çıkanlar kısayolu).
    let deckID: UUID?

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppRouter.self) private var router
    @Environment(GameSetup.self) private var setup
    @Environment(SubscriptionStore.self) private var subscription
    @Environment(\.modelContext) private var modelContext

    /// Deste sayısı en fazla 3; predicate yazmak yerine istemcide seçmek ucuz.
    @Query private var decks: [CustomDeck]

    @State private var createdID: UUID?
    @FocusState private var isNamingFocused: Bool

    private var deck: CustomDeck? {
        let id = deckID ?? createdID
        return decks.first { $0.uuid == id }
    }

    var body: some View {
        ZStack {
            VelvetBackground()

            if let deck {
                editor(deck)
            }
        }
        .onAppear(perform: createIfNeeded)
        // Adsız ve kelimesiz deste listede iz bırakmıyor: kullanıcı `Yeni Deste`ye
        // yanlışlıkla dokunup geri döndüğünde boş bir kart kalmamalı.
        .onDisappear(perform: discardIfEmpty)
    }

    private func editor(_ deck: CustomDeck) -> some View {
        @Bindable var deck = deck

        return VStack(spacing: 0) {
            navBar(deck)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 14) {
                        // §05 §7: "marquee önizlemesi canlı güncellenir" —
                        // isim ve kapak değiştikçe ızgarada nasıl görüneceği.
                        CustomDeckCard(deck: deck, isLocked: false)
                            .frame(width: 96)

                        nameField(deck)
                    }

                    field(label: l10n.t("customDeck.field.cover")) {
                        CoverPicker(
                            selection: Binding(
                                get: { deck.cover },
                                set: { deck.coverTemplate = $0.rawValue }
                            ),
                            imageData: $deck.coverImageData
                        )
                        // Şerit ekranın kenarına kadar kaysın: 12 şablon
                        // 20pt'lik iç boşlukta kesik görünüyordu.
                        .padding(.horizontal, -20)
                    }

                    field(label: l10n.t("customDeck.field.words")) {
                        WordListSection(words: wordsBinding(deck))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            footer(deck)
        }
    }

    // MARK: Başlık

    private func navBar(_ deck: CustomDeck) -> some View {
        HStack(spacing: 0) {
            Button {
                Haptics.secondaryButton()
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .flipsForRightToLeftLayoutDirection(true)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.accentGold)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.t("common.back"))

            VStack(spacing: 2) {
                Text(deck.name.isEmpty ? l10n.t("customDeck.defaultName") : deck.name)
                    .font(AppFont.display(19, weight: .bold))
                    .appTracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textCream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(l10n.t("customDeck.autosave"))
                    .font(AppFont.ui(10.5))
                    .foregroundStyle(AppColors.textMuted)
            }
            .frame(maxWidth: .infinity)

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
    }

    // MARK: Alanlar

    private func field(label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("◆ \(label)")
                .font(AppFont.ui(10, weight: .semibold))
                .appTracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.accentGold)

            content()
        }
    }

    private func nameField(_ deck: CustomDeck) -> some View {
        @Bindable var deck = deck

        return field(label: l10n.t("customDeck.field.name")) {
            VStack(alignment: .leading, spacing: 7) {
                TextField(l10n.t("customDeck.name.placeholder"), text: $deck.name)
                    .font(AppFont.display(16, weight: .medium))
                    .foregroundStyle(AppColors.textCream)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($isNamingFocused)
                    // 24 karakter sınırı yazarken uygulanıyor; sonradan kırpmak
                    // kullanıcının yazdığını sessizce yutmak olurdu.
                    .onChange(of: deck.name) { _, new in
                        if new.count > CustomDeckLimits.maxNameLength {
                            deck.name = String(new.prefix(CustomDeckLimits.maxNameLength))
                            Haptics.stepperLimit()
                        }
                        deck.updatedAt = .now
                    }
                    .padding(.horizontal, 13)
                    .frame(height: 46)
                    .background {
                        RoundedRectangle(cornerRadius: 11)
                            .fill(AppColors.bgFilmBlack.opacity(0.66))
                            .overlay {
                                RoundedRectangle(cornerRadius: 11).strokeBorder(
                                    isNamingFocused
                                        ? AppColors.accentAmber
                                        : AppColors.accentGold.opacity(0.34),
                                    lineWidth: 1
                                )
                            }
                    }

                Text("\(deck.name.count) / \(CustomDeckLimits.maxNameLength)")
                    .font(AppFont.ui(9.5))
                    .monospacedDigit()
                    .foregroundStyle(AppColors.textMuted)
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

    // MARK: Alt bar

    private func footer(_ deck: CustomDeck) -> some View {
        VStack(spacing: 7) {
            if !deck.canPlay {
                Text(l10n.t("customDeck.needsMore", count: CustomDeckLimits.minWordsToPlay))
                    .font(AppFont.ui(11))
                    .foregroundStyle(AppColors.stateWarning)
            }

            HStack(spacing: 10) {
                Button {
                    commitAndPop()
                } label: {
                    // İki butonun yüksekliği eşit kalmalı: `KAYDET VE OYNA`
                    // uzun dillerde iki satıra taşıp yanındakini kısa bırakıyor.
                    Text(l10n.t("customDeck.save")).lineLimit(1)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    play(deck)
                } label: {
                    Text(l10n.t("customDeck.saveAndPlay"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .buttonStyle(MarqueeButtonStyle())
                .disabled(!deck.canPlay)
            }
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

    // MARK: Eylemler

    private func createIfNeeded() {
        guard deckID == nil, createdID == nil else { return }
        let deck = CustomDeck(
            name: l10n.t("customDeck.defaultName"),
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
        // Çıkmadan önce flush: ilişki henüz yazılmamışsa kelimeli deste
        // yanlışlıkla "boş" sayılıp silinmesin.
        modelContext.persistCustomDecks()
        guard deck.wordCount == 0 else { return }
        let name = deck.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.isEmpty || name == l10n.t("customDeck.defaultName") else { return }
        modelContext.delete(deck)
        modelContext.persistCustomDecks()
    }

    private func commitAndPop() {
        Haptics.primaryButton()
        modelContext.persistCustomDecks()
        router.pop()
    }

    private func play(_ deck: CustomDeck) {
        // §09 §9: yazmak ücretsiz, oynamak Tam Bilet. Duvar burada çıkıyor —
        // kullanıcı destesini bitirmiş, ne satın alacağını görüyor.
        modelContext.persistCustomDecks()
        guard subscription.isPremium else {
            Haptics.lockedWall()
            router.openPaywall(.customDeck)
            return
        }
        Haptics.primaryButton()
        setup.select(custom: deck.uuid)
        router.popToRoot()
        router.beginSetup()
    }
}

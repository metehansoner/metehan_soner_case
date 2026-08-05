import SwiftUI

/// Kelime Sepeti (ekran 24) — 02-ekran-akisi.md §24.
///
/// Tek işi var: kullanıcı kelimeleri yazsın ve oyuna girsin. Kaydetme burada
/// **yok** — isim alanı koymak custom deste editörünün akışa taktığı freni geri
/// getirirdi. Kaydetme tur sonunda soruluyor (`SaveBasketBanner`).
struct WordBasketView: View {
    /// Kurulum sheet'ine (mod + tur ayarı) dönülüyor.
    var onContinue: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppRouter.self) private var router
    @Environment(GameSetup.self) private var setup

    @State private var wordDraft = ""

    private var isPlayableIncludingDraft: Bool {
        let words = setup.basketWords
        let draft = wordDraft
        let result = WordList.inserting(draft, into: words, limit: CustomDeckLimits.maxWords)
        let count = result.addedCount > 0 ? result.words.count : words.count
        return count >= CustomDeckLimits.minWordsToPlay
    }

    var body: some View {
        @Bindable var setup = setup

        return ZStack {
            VelvetBackground()

            VStack(spacing: 0) {
                navBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header

                        WordListSection(
                            words: $setup.basketWords,
                            draft: $wordDraft,
                            autoFocusesEntry: true
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)

                footer
            }
        }
        .dismissKeyboardOnTap()
    }

    // MARK: Başlık

    private var navBar: some View {
        HStack(spacing: 0) {
            // §02 §24: geri mod seçimine dönüyor ve yazılanlar korunuyor —
            // kelimeler `GameSetup`ta, bu ekranın state'inde değil.
            BackNavButton(accessibilityLabel: l10n.t("common.back")) {
                router.pop()
            }

            Spacer(minLength: 0)

            Button {
                Haptics.secondaryButton()
                router.openHowToPlay(for: .ownWords)
            } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColors.accentGold)
                    .frame(width: BackNavButton.hitSide, height: BackNavButton.hitSide)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.t("howToPlay.title"))
        }
        .padding(.horizontal, 8)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(l10n.t("basket.title"))
                .font(AppFont.display(28, weight: .bold))
                .appTracking(4)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textCream)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(l10n.t("basket.subtitle"))
                .font(AppFont.ui(12))
                .foregroundStyle(AppColors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Alt bar

    private var footer: some View {
        VStack(spacing: 7) {
            if !isPlayableIncludingDraft {
                Text(l10n.t("words.hint.min"))
                    .font(AppFont.ui(11))
                    .foregroundStyle(AppColors.stateWarning)
            }

            Button(l10n.t("common.play")) {
                Haptics.primaryButton()
                var words = setup.basketWords
                if WordDraft.flush(draft: &wordDraft, into: &words).addedCount > 0 {
                    setup.basketWords = words
                }
                onContinue()
            }
            .buttonStyle(MarqueeButtonStyle())
            .disabled(!isPlayableIncludingDraft)
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
}

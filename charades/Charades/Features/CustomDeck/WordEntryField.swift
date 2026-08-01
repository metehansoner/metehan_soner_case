import SwiftUI

/// Kelime giriş bölümü — 05-desteler-ve-kategoriler.md §7 ve 02-ekran-akisi.md §24.
///
/// Custom deste editörü ile Kelime Sepeti bu bileşeni paylaşıyor: giriş satırı,
/// sayaç, toplu ekleme ve chip listesi tek yerde. İki ekranda "aynı kelimeyi iki
/// kez ekledim" ya da "Enter'a bastım" davranışının ayrışması kullanıcıya hata
/// gibi görünürdü.
struct WordListSection: View {
    @Binding var words: [String]
    /// Ekran açılır açılmaz klavye — sepette şart (§02 §24), editörde önce isim
    /// alanı doldurulduğu için kapalı.
    var autoFocusesEntry = false

    @Environment(LocalizationManager.self) private var l10n

    @State private var draft = ""
    @State private var flashedIndex: Int?
    @State private var isBulkPasting = false
    @FocusState private var isEntryFocused: Bool

    private var isFull: Bool { words.count >= CustomDeckLimits.maxWords }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            entryRow

            counterRow
                .padding(.top, 13)

            if !words.isEmpty {
                chips
                    .padding(.top, 14)
            }
        }
        .sheet(isPresented: $isBulkPasting) {
            BulkPasteSheet(remaining: CustomDeckLimits.maxWords - words.count) { text in
                merge(text)
            }
            .environment(l10n)
        }
        .onAppear {
            #if DEBUG
            // Mağaza karesinde klavye ekranın yarısını yiyor.
            if ProcessInfo.processInfo.arguments.contains("-NoKeyboard") { return }
            #endif
            if autoFocusesEntry { isEntryFocused = true }
        }
    }

    // MARK: Giriş satırı

    private var entryRow: some View {
        HStack(spacing: 8) {
            TextField(l10n.t("words.placeholder"), text: $draft)
                .font(AppFont.display(15, weight: .medium))
                .appTracking(1)
                .foregroundStyle(AppColors.textCream)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                // §02 §24: Enter kelimeyi ekliyor ve alanı boşaltıyor, klavye
                // **kapanmıyor** — 20 kelime yazan kullanıcı için tek önemli detay.
                .submitLabel(.next)
                .focused($isEntryFocused)
                .onSubmit(add)
                .disabled(isFull)

            Button(action: add) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(AppColors.textOnAmber)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(AppColors.accentAmber))
                    .tapTarget()
            }
            .buttonStyle(.plain)
            .disabled(draft.isEmpty || isFull)
            .opacity(draft.isEmpty || isFull ? 0.4 : 1)
            .accessibilityLabel(l10n.t("words.add"))
        }
        .padding(.horizontal, 13)
        .frame(height: 46)
        .background {
            RoundedRectangle(cornerRadius: 11)
                .fill(AppColors.bgFilmBlack.opacity(0.66))
                .overlay {
                    RoundedRectangle(cornerRadius: 11).strokeBorder(
                        isEntryFocused ? AppColors.accentAmber : AppColors.accentGold.opacity(0.34),
                        lineWidth: 1
                    )
                }
        }
    }

    // MARK: Sayaç

    private var counterRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if let hint {
                Text(hint)
                    .font(AppFont.ui(10))
                    .appTracking(0.6)
                    .foregroundStyle(words.count < CustomDeckLimits.minWordsToPlay
                        ? AppColors.stateWarning
                        : AppColors.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button {
                Haptics.secondaryButton()
                isEntryFocused = false
                isBulkPasting = true
            } label: {
                Label(l10n.t("words.bulkAdd"), systemImage: "text.append")
                    .font(AppFont.ui(10, weight: .semibold))
                    .appTracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(isFull ? AppColors.stateLocked : AppColors.accentGold)
            }
            .buttonStyle(.plain)
            .disabled(isFull)

            Text("\(words.count) / \(CustomDeckLimits.maxWords)")
                .font(AppFont.display(14, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(AppColors.accentAmber)
        }
    }

    /// §02 §6: 5 altında engel, §09 §4: 20 altında tavsiye.
    private var hint: String? {
        if isFull { return l10n.t("words.limitReached") }
        if words.count < CustomDeckLimits.minWordsToPlay { return l10n.t("words.hint.min") }
        if words.count < CustomDeckLimits.recommendedWordCount { return l10n.t("words.hint.recommended") }
        return nil
    }

    // MARK: Kelime chip'leri

    private var chips: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 104), spacing: 7)],
            alignment: .leading,
            spacing: 7
        ) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                chip(index: index, word: word)
            }
        }
    }

    private func chip(index: Int, word: String) -> some View {
        let isFlashed = flashedIndex == index

        return HStack(spacing: 6) {
            Text(word)
                .font(AppFont.display(13, weight: .medium))
                .appTracking(0.9)
                .foregroundStyle(AppColors.textCream)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            Button {
                remove(at: index)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.textMuted)
                    .frame(width: 18, height: 18)
                    // Chip'in içinde: 44pt satırı boyuna zorluyor, 34 hem
                    // vurulabilir hem şeridi bozmuyor.
                    .tapTarget(34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.t("words.remove"))
        }
        .padding(.leading, 11)
        .padding(.trailing, 3)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 7)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x4A3016).opacity(isFlashed ? 0.95 : 0.45),
                            AppColors.surfaceCard.opacity(0.75),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 7).strokeBorder(
                        isFlashed ? AppColors.accentAmber : AppColors.accentGold.opacity(0.28),
                        lineWidth: isFlashed ? 1.5 : 1
                    )
                }
        }
        .animation(.easeOut(duration: 0.18), value: isFlashed)
    }

    // MARK: Eylemler

    private func add() {
        let result = WordList.inserting(draft, into: words, limit: CustomDeckLimits.maxWords)

        if let duplicate = result.duplicateIndex {
            // §02 §24: tekrar eden kelime sessizce eklenmiyor, mevcut satır bir an
            // amber yanıyor. Parti ortamında modal okunmuyor, uyarı metni yok.
            draft = ""
            flash(duplicate)
            return
        }
        guard result.addedCount > 0 else {
            if result.hitLimit { Haptics.stepperLimit() }
            return
        }
        Haptics.selection()
        words = result.words
        draft = ""
        // Klavye açık kalıyor; odak kaybı 20 kelimelik girişi bitiriyor.
        isEntryFocused = true
        Analytics.customDeckWordAdd(wordCount: result.addedCount)
    }

    private func merge(_ text: String) {
        let result = WordList.merging(text, into: words, limit: CustomDeckLimits.maxWords)
        guard result.addedCount > 0 else {
            Haptics.stepperLimit()
            return
        }
        Haptics.selection()
        words = result.words
        Analytics.customDeckWordAdd(wordCount: result.addedCount)
    }

    private func remove(at index: Int) {
        guard words.indices.contains(index) else { return }
        Haptics.deckDeselected()
        _ = withAnimation(.easeOut(duration: 0.18)) {
            words.remove(at: index)
        }
    }

    private func flash(_ index: Int) {
        flashedIndex = index
        Haptics.stepperLimit()
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            if flashedIndex == index { flashedIndex = nil }
        }
    }
}

import SwiftUI


struct WordListSection: View {
    @Binding var words: [String]
    @Binding var draft: String


    var autoFocusesEntry = false

    @Environment(LocalizationManager.self) private var l10n

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

            if ProcessInfo.processInfo.arguments.contains("-NoKeyboard") { return }
            #endif
            if autoFocusesEntry { isEntryFocused = true }
        }

        .onDisappear {
            WordDraft.flush(draft: $draft, into: $words)
        }
    }


    private var entryRow: some View {
        HStack(spacing: 10) {
            TextField(l10n.t("words.placeholder"), text: $draft)
                .font(AppFont.display(18, weight: .medium))
                .appTracking(0.6)
                .foregroundStyle(AppColors.textCream)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($isEntryFocused)
                .onSubmit(add)
                .disabled(isFull)

            Button {
                Haptics.secondaryButton()
                isEntryFocused = false
                isBulkPasting = true
            } label: {
                Image(systemName: "text.append")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isFull ? AppColors.stateLocked : AppColors.accentGold)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .disabled(isFull)
            .accessibilityLabel(l10n.t("words.bulkAdd"))

            Image(systemName: "plus")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(AppColors.textOnAmber)
                .frame(width: 36, height: 36)
                .background(Circle().fill(AppColors.accentAmber))
                .opacity(draft.isEmpty || isFull ? 0.4 : 1)
                .tapTarget(44)
                .onTapGesture {
                    guard !draft.isEmpty, !isFull else { return }
                    add()
                }
                .accessibilityLabel(l10n.t("words.add"))
                .accessibilityAddTraits(.isButton)
                .accessibilityRemoveTraits(.isImage)
        }
        .padding(.leading, 16)
        .padding(.trailing, 10)
        .frame(height: 56)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.bgFilmBlack.opacity(0.66))
                .overlay {
                    RoundedRectangle(cornerRadius: 14).strokeBorder(
                        isEntryFocused ? AppColors.accentAmber : AppColors.accentGold.opacity(0.34),
                        lineWidth: 1
                    )
                }
        }
    }


    private var counterRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if let hint {
                Text(hint)
                    .font(AppFont.ui(13))
                    .foregroundStyle(words.count < CustomDeckLimits.minWordsToPlay
                        ? AppColors.stateWarning
                        : AppColors.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Text("\(words.count) / \(CustomDeckLimits.maxWords)")
                .font(AppFont.display(16, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(AppColors.accentAmber)
        }
    }


    private var hint: String? {
        if isFull { return l10n.t("words.limitReached") }
        return nil
    }


    private var chips: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 128), spacing: 8)],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(Array(words.enumerated()), id: \.element) { index, word in
                chip(index: index, word: word)
            }
        }
    }

    private func chip(index: Int, word: String) -> some View {
        let isFlashed = flashedIndex == index

        return HStack(spacing: 8) {
            Text(word)
                .font(AppFont.display(15, weight: .medium))
                .appTracking(0.6)
                .foregroundStyle(AppColors.textCream)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            Button {
                remove(at: index)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.textMuted)
                    .frame(width: 22, height: 22)
                    .tapTarget(36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.t("words.remove"))
        }
        .padding(.leading, 14)
        .padding(.trailing, 6)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 10)
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
                    RoundedRectangle(cornerRadius: 10).strokeBorder(
                        isFlashed ? AppColors.accentAmber : AppColors.accentGold.opacity(0.28),
                        lineWidth: isFlashed ? 1.5 : 1
                    )
                }
        }
        .animation(.easeOut(duration: 0.18), value: isFlashed)
    }


    private func add() {
        let result = WordDraft.flush(draft: $draft, into: $words)

        if let duplicate = result.duplicateIndex {


            flash(duplicate)
            return
        }
        guard result.addedCount > 0 else {
            if result.hitLimit { Haptics.stepperLimit() }
            return
        }
        Haptics.selection()
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


enum WordDraft {
    @discardableResult
    static func flush(draft: inout String, into words: inout [String]) -> WordList.Insertion {
        let result = WordList.inserting(draft, into: words, limit: CustomDeckLimits.maxWords)
        if result.duplicateIndex != nil {
            draft = ""
            return result
        }
        guard result.addedCount > 0 else { return result }
        words = result.words
        draft = ""
        return result
    }

    @discardableResult
    static func flush(draft: Binding<String>, into words: Binding<[String]>) -> WordList.Insertion {
        var draftValue = draft.wrappedValue
        var wordsValue = words.wrappedValue
        let result = flush(draft: &draftValue, into: &wordsValue)
        draft.wrappedValue = draftValue
        words.wrappedValue = wordsValue
        return result
    }
}

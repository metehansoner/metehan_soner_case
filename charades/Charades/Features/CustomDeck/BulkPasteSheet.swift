import SwiftUI

/// Toplu ekleme — 05-desteler-ve-kategoriler.md §7.
///
/// Tek tek yazmak 40 kelimelik bir deste için işkence; notlar uygulamasından ya
/// da WhatsApp'tan yapıştırılan liste tek dokunuşla giriyor. Ayraç satır sonu,
/// virgül ya da noktalı virgül (§ `WordList.parse`).
struct BulkPasteSheet: View {
    /// Limit dolmadan kaç kelime alınabilir — kullanıcı 80 kelime yapıştırıp
    /// yalnızca 12'sinin girdiğini sonradan fark etmesin.
    let remaining: Int
    let onAdd: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var l10n

    @State private var text = ""
    @FocusState private var isFocused: Bool

    private var parsed: [String] { WordList.parse(text) }
    private var overflow: Int { max(0, parsed.count - remaining) }

    var body: some View {
        SheetScaffold(title: l10n.t("words.bulk.title")) {
            dismiss()
        } content: {
            VStack(alignment: .leading, spacing: 14) {
                Text(l10n.t("words.bulk.hint"))
                    .font(AppFont.ui(12))
                    .foregroundStyle(AppColors.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                editor

                HStack {
                    Text(counterText)
                        .font(AppFont.ui(11))
                        .foregroundStyle(overflow > 0 ? AppColors.stateWarning : AppColors.textMuted)
                    Spacer(minLength: 0)
                }

                Spacer(minLength: 0)

                Button {
                    Haptics.primaryButton()
                    onAdd(text)
                    dismiss()
                } label: {
                    Text(l10n.t("words.bulk.action"))
                }
                .buttonStyle(MarqueeButtonStyle())
                .disabled(parsed.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
        .presentationDetents([.fraction(0.62)])
        .onAppear { isFocused = true }
    }

    private var editor: some View {
        TextEditor(text: $text)
            .font(AppFont.display(15))
            .foregroundStyle(AppColors.textCream)
            .scrollContentBackground(.hidden)
            .autocorrectionDisabled()
            .focused($isFocused)
            .padding(10)
            .frame(minHeight: 150)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.bgFilmBlack.opacity(0.66))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12).strokeBorder(
                            isFocused ? AppColors.accentAmber : AppColors.accentGold.opacity(0.3),
                            lineWidth: 1
                        )
                    }
            }
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(l10n.t("words.bulk.placeholder"))
                        .font(AppFont.display(15))
                        .foregroundStyle(AppColors.textMuted.opacity(0.7))
                        .padding(16)
                        .allowsHitTesting(false)
                }
            }
    }

    private var counterText: String {
        if overflow > 0 {
            return l10n.t("words.bulk.overflow", ["count": "\(remaining)", "extra": "\(overflow)"])
        }
        return l10n.t("words.bulk.found", count: parsed.count)
    }
}

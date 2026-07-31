import SwiftUI

/// Mix Kurulumu'ndaki kayıtlı karışımlar satırı — 05-desteler-ve-kategoriler.md §6.
///
/// Buradaki iş "yükle": kaydedilmiş bir karışıma dokunmak seçimi olduğu gibi
/// geri getiriyor. Silme ve oynatma ana ekrandaki kartın işi (`SavedMixCard`);
/// aynı eylemi iki yerde tekrarlamak sınırlı 5 slotta kafa karıştırırdı.
struct SavedMixesRow: View {
    let mixes: [SavedMix]
    let appliedIDs: [String]
    var onApply: (SavedMix) -> Void

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(l10n.t("mix.saved.title"))
                    .font(AppFont.ui(10.5, weight: .bold))
                    .tracking(2.4)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.accentGold)

                Spacer()

                Text("\(mixes.count)/\(MixLimits.maxSaved)")
                    .font(AppFont.ui(10))
                    .monospacedDigit()
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(mixes) { mix in
                        chip(mix)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private func chip(_ mix: SavedMix) -> some View {
        let isApplied = mix.deckIDs == appliedIDs

        return Button {
            onApply(mix)
        } label: {
            HStack(spacing: 8) {
                MixCollage(decks: mix.decks)
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 1) {
                    Text(mix.name)
                        .font(AppFont.ui(12, weight: .semibold))
                        .foregroundStyle(AppColors.textCream)
                        .lineLimit(1)

                    Text(l10n.t("mix.deckCount", count: mix.deckIDs.count))
                    .font(AppFont.ui(9.5))
                    .foregroundStyle(AppColors.textMuted)
                }
            }
            .padding(.leading, 7)
            .padding(.trailing, 12)
            .padding(.vertical, 7)
            .background {
                Capsule()
                    .fill(AppColors.surfaceCard.opacity(0.85))
                    .overlay {
                        Capsule().strokeBorder(
                            isApplied ? AppColors.accentAmber : AppColors.accentGold.opacity(0.3),
                            lineWidth: isApplied ? 1.5 : 1
                        )
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isApplied ? [.isButton, .isSelected] : .isButton)
    }
}

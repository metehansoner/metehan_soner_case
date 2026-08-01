import SwiftUI

/// Filtre chip satırı — 02-ekran-akisi.md §4 (ekran 4, madde 2).
///
/// 16 chip: 3 dinamik/genel + 13 bölüm. Sayının bölüm sayısıyla eşleşmesi
/// `DeckFilter.section(_:)` modellemesiyle derleme zamanında garanti
/// (`DeckSection.swift`); burada yalnızca koşullu iki chip'in kuralı var:
/// `FAVORİLER` en az bir favori varken (§09 §9), `SEZON` yalnızca bir sezon
/// destesinin penceresi açıkken görünüyor.
struct FilterChipRow: View {
    @Binding var selection: DeckFilter
    var favoriteCount: Int
    var date: Date = .now

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Reduce Motion'da şerit kaymıyor, seçilen chip doğrudan ortada beliriyor.
    private var scrollAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.22)
    }

    private var filters: [DeckFilter] {
        var result = DeckFilter.standardOrder
        if !DeckCatalog.decks(in: .seasonal).contains(where: { $0.isInSeason(on: date) }) {
            result.removeAll { $0 == .section(.seasonal) }
        }
        if favoriteCount > 0 {
            result.insert(.favorites, at: 1)
        }
        return result
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filters) { filter in
                        FilterChip(
                            title: l10n.t(filter.titleKey),
                            isActive: filter == selection
                        ) {
                            guard filter != selection else { return }
                            Haptics.selection()
                            selection = filter
                            withAnimation(scrollAnimation) {
                                proxy.scrollTo(filter.id, anchor: .center)
                            }
                        }
                        .id(filter.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
            // §4: chip sayısı 16'ya çıktığı için satır sonunda gradient fade —
            // kaydırılabilir olduğu görsel olarak belli olsun.
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.92),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .onChange(of: selection) { _, new in
                withAnimation(scrollAnimation) { proxy.scrollTo(new.id, anchor: .center) }
            }
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .textStyle(.sectionLabel)
                .foregroundStyle(isActive ? AppColors.textOnAmber : AppColors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(isActive ? AppColors.accentAmber : Color.clear)
                        .overlay {
                            Capsule().strokeBorder(
                                isActive ? .clear : AppColors.accentGold.opacity(0.45),
                                lineWidth: 1
                            )
                        }
                }
                // §4: aktif chip'in ampul çerçevesi.
                .overlay {
                    if isActive {
                        BulbFrame(countPerEdge: 5, diameter: 2.5, color: AppColors.surfacePoster)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 2.5)
                    }
                }
                // Kapsül 30pt görünüyor; şeridin dokunma alanı 44pt.
                .tapTarget()
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }
}

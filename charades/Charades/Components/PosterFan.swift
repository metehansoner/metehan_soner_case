import SwiftUI

/// Yelpaze gibi açılmış dört afiş — 01-tasarim-sistemi.md §6.2.
///
/// Ayrı bir illüstrasyon üretilmiyor: kapaklar zaten bundle'da (§ `05` §8) ve
/// kullanıcı bir sonraki ekranda tam olarak bunları görecek. Onboarding adım 1
/// (§ `03` §1) ve Nasıl Oynanır sayfa 1 (§ `02` §4) aynı görseli paylaşıyor.
struct PosterFan: View {
    var deckIDs: [String] = ["party", "movieClassics", "animals", "nineties"]

    private static let angles: [Double] = [-16, -5.5, 5.5, 16]

    var body: some View {
        ZStack {
            ForEach(Array(deckIDs.prefix(Self.angles.count).enumerated()), id: \.offset) { index, id in
                let angle = Self.angles[index]
                FanPoster(deckID: id)
                    .rotationEffect(.degrees(angle), anchor: .bottom)
                    .offset(x: CGFloat(angle) * 3.6, y: abs(angle) * 0.9)
                    .zIndex(Double(index))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .accessibilityHidden(true)
    }
}

private struct FanPoster: View {
    let deckID: String

    var body: some View {
        let section = DeckCatalog.deck(deckID)?.section ?? .party
        RoundedRectangle(cornerRadius: 8)
            .fill(AppColors.surfaceCard)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(AppColors.accentGold.opacity(0.55), lineWidth: 1)
            }
            .overlay {
                VStack(spacing: 0) {
                    ZStack {
                        section.artGradient
                        Image("deck_\(deckID)")
                            .resizable()
                            .scaledToFit()
                            .padding(7)
                    }
                    Rectangle()
                        .fill(AppColors.surfaceTicket)
                        .frame(height: 11)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(3)
            }
            .frame(width: 74, height: 99)
            .shadow(color: .black.opacity(0.5), radius: 5, y: 3)
    }
}

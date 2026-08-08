import SwiftUI

/// Yelpaze gibi açılmış dört afiş — 01-tasarim-sistemi.md §6.2.
///
/// Ayrı bir illüstrasyon üretilmiyor: kapaklar zaten bundle'da (§ `05` §8) ve
/// kullanıcı bir sonraki ekranda tam olarak bunları görecek. Onboarding adım 1
/// (§ `03` §1) ve Nasıl Oynanır sayfa 1 (§ `02` §4) aynı görseli paylaşıyor.
struct PosterFan: View {
    var deckIDs: [String] = ["party", "movieClassics", "animals", "nineties"]

    private static let angles: [Double] = [-15, -5, 5, 15]

    var body: some View {
        ZStack {
            ForEach(Array(deckIDs.prefix(Self.angles.count).enumerated()), id: \.offset) { index, id in
                let angle = Self.angles[index]
                FanPoster(deckID: id)
                    .rotationEffect(.degrees(angle), anchor: .bottom)
                    .offset(x: CGFloat(angle) * 4.8, y: abs(angle) * 1.15)
                    .zIndex(Double(index))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .accessibilityHidden(true)
    }
}

private struct FanPoster: View {
    let deckID: String

    @Environment(LocalizationManager.self) private var l10n

    private var deck: DeckDef? { DeckCatalog.deck(deckID) }
    private var section: DeckSection { deck?.section ?? .party }
    private var titleKey: String { deck?.titleKey ?? "deck.\(deckID).title" }
    private var imageName: String { deck?.imageName ?? "deck_\(deckID)" }

    var body: some View {
        RoundedRectangle(cornerRadius: 11)
            .fill(AppColors.surfaceCard)
            .overlay {
                RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(AppColors.accentGold.opacity(0.55), lineWidth: 1.2)
            }
            .overlay {
                VStack(spacing: 0) {
                    ZStack {
                        section.artGradient
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .padding(10)
                    }

                    Text(l10n.t(titleKey))
                        .font(AppFont.accent(11, weight: .black))
                        .lineSpacing(-1)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(AppColors.textOnPoster)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 5)
                        .padding(.top, 5)
                        .padding(.bottom, 6)
                        .background {
                            LinearGradient(
                                colors: [AppColors.surfacePoster, AppColors.surfaceTicket],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(4)
            }
            .frame(width: 118, height: 160)
            .shadow(color: .black.opacity(0.5), radius: 7, y: 5)
    }
}

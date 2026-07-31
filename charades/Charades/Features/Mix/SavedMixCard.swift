import SwiftUI

/// Kaydedilmiş karışımın ana ekran kartı — 05-desteler-ve-kategoriler.md §6.
///
/// `BENİM DESTELERİM` ızgarasında deste kartlarıyla aynı 3:4 ölçüde duruyor;
/// ayrıştıran tek şey kapak: tek afiş yerine seçili destelerin kolajı ve
/// köşedeki `MIX` etiketi.
struct SavedMixCard: View {
    let mix: SavedMix

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                MixCollage(decks: mix.decks)
                    .overlay(alignment: .bottomTrailing) {
                        if mix.deckIDs.count > MixCollage.visibleDeckLimit {
                            Text("+\(mix.deckIDs.count - MixCollage.visibleDeckLimit)")
                                .font(AppFont.display(11, weight: .bold))
                                .foregroundStyle(AppColors.textCream)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(AppColors.bgFilmBlack.opacity(0.75)))
                                .padding(6)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                titleStrip
            }

            tag
        }
        .padding(5)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.surfaceCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AppColors.accentGold.opacity(0.38), lineWidth: 1)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.55), radius: 8, y: 5)
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(l10n.t("featured.mix")), \(mix.name), \(deckSummary)")
        .accessibilityAddTraits(.isButton)
    }

    private var titleStrip: some View {
        VStack(spacing: 1) {
            Text(mix.name)
                .font(AppFont.display(11, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(AppColors.textCream)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(deckSummary)
                .font(AppFont.ui(8))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
    }

    private var deckSummary: String {
        let decks = l10n.t(
            mix.deckIDs.count == 1 ? "mix.deckCount" : "mix.deckCount.plural",
            ["count": "\(mix.deckIDs.count)"]
        )
        return "\(decks) · \(l10n.t("playbar.cards", ["cards": "\(mix.cardCount)"]))"
    }

    private var tag: some View {
        Text(l10n.t("featured.mix"))
            .font(AppFont.display(8, weight: .bold))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textOnAmber)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Capsule().fill(AppColors.accentAmber))
            .padding(8)
    }
}

/// Karışım kapağı: seçili destelerin bölüm renklerinden kolaj.
///
/// Deste kapak görselleri (P2'de `deck_*`) burada kullanılmıyor — dört afişi
/// küçültüp yan yana koymak okunmaz bir bulamaç veriyor. Bölümlerin baskın
/// tonları aynı bilgiyi kart boyutunda taşıyor.
struct MixCollage: View {
    let decks: [DeckDef]

    static let visibleDeckLimit = 4

    var body: some View {
        let shown = Array(decks.prefix(Self.visibleDeckLimit))

        ZStack {
            AppColors.bgVelvetDeep

            switch shown.count {
            case 0:
                EmptyView()
            case 1:
                tile(shown[0])
            case 2:
                HStack(spacing: 1) {
                    tile(shown[0])
                    tile(shown[1])
                }
            case 3:
                HStack(spacing: 1) {
                    tile(shown[0])
                    VStack(spacing: 1) {
                        tile(shown[1])
                        tile(shown[2])
                    }
                }
            default:
                VStack(spacing: 1) {
                    HStack(spacing: 1) {
                        tile(shown[0])
                        tile(shown[1])
                    }
                    HStack(spacing: 1) {
                        tile(shown[2])
                        tile(shown[3])
                    }
                }
            }

            HalftoneTexture(dotSize: 0.7, spacing: 4, color: .black)
                .opacity(0.18)
                .allowsHitTesting(false)
        }
    }

    private func tile(_ deck: DeckDef) -> some View {
        Rectangle().fill(deck.section.artGradient)
    }
}

import SwiftUI

/// Custom destenin ana ekran ızgarasındaki afişi.
///
/// `DeckCard` anatomisini birebir tekrarlıyor (afiş + başlık şeridi + altın
/// çerçeve) ama kendi tipini kullanıyor: `DeckDef` katalog kimliği, `titleKey`
/// ve bölüm rengi istiyor, custom destede üçü de yok. Ortak gövdeyi
/// soyutlamak yerine kopyalamak, iki kart tipinin ayrı ayrı evrilmesine izin
/// veriyor — custom kartın dil etiketi ve `TASLAK` şeridi katalogda yok.
struct CustomDeckCard: View {
    let deck: CustomDeck
    /// §09 §9: ücretsiz kullanıcı yazabiliyor ama oynayamıyor.
    var isLocked: Bool

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        ZStack {
            poster
                .saturation(isLocked ? 0.3 : 1)
                .brightness(isLocked ? -0.22 : 0)
                .colorMultiply(isLocked ? Color(hex: 0xC9A98A) : .white)

            if isLocked {
                lockLayer
            }

            languageTag
            if !deck.canPlay {
                draftRibbon
            }
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
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var poster: some View {
        VStack(spacing: 0) {
            CustomCoverArt(cover: deck.cover, imageData: deck.coverImageData)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            titleStrip
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(AppColors.accentGold.opacity(0.3), lineWidth: 1)
        }
    }

    private var titleStrip: some View {
        VStack(spacing: 2) {
            Text(deck.name)
                .font(AppFont.accent(13, weight: .black))
                .lineSpacing(-1)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .foregroundStyle(AppColors.textOnPoster)

            Text(l10n.t("customDeck.wordCount", count: deck.wordCount))
                .font(AppFont.ui(7.5, weight: .semibold))
                .appTracking(1.3)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textOnPosterMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 7)
        .padding(.top, 6)
        .padding(.bottom, 7)
        .background {
            LinearGradient(
                colors: [AppColors.surfacePoster, AppColors.surfaceTicket],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    /// §05 §7: custom kelimeler çevrilmiyor; kart hangi dilde yazıldığını
    /// söylüyor ki kullanıcı dili değiştirince şaşırmasın.
    private var languageTag: some View {
        Text(deck.languageCode.uppercased())
            .font(AppFont.ui(6.5, weight: .bold))
            .appTracking(1)
            .foregroundStyle(AppColors.accentGold)
            .padding(.horizontal, 5)
            .padding(.vertical, 2.5)
            .background {
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.bgFilmBlack.opacity(0.72))
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(AppColors.accentGold.opacity(0.4), lineWidth: 0.5)
                    }
            }
            .padding(9)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var draftRibbon: some View {
        Text(l10n.t("customDeck.draft.badge"))
            .font(AppFont.ui(6.5, weight: .bold))
            .appTracking(1)
            .textCase(.uppercase)
            .foregroundStyle(AppColors.textOnAmber)
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background { RoundedRectangle(cornerRadius: 3).fill(AppColors.stateWarning) }
            .padding(9)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private var lockLayer: some View {
        VStack(spacing: 7) {
            Image(systemName: "lock.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(AppColors.accentBrass)

            Text(l10n.t("deck.locked.stamp"))
                .font(AppFont.display(8, weight: .semibold))
                .appTracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.accentGold)
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .overlay {
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(AppColors.accentGold, lineWidth: 1.5)
                }
                .rotationEffect(.degrees(-7))
                .opacity(0.9)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.bgFilmBlack.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var accessibilityLabel: String {
        var parts = [deck.name, l10n.t("customDeck.wordCount", count: deck.wordCount)]
        if !deck.canPlay { parts.append(l10n.t("customDeck.draft.badge")) }
        if isLocked { parts.append(l10n.t("deck.locked.stamp")) }
        return parts.joined(separator: ", ")
    }
}

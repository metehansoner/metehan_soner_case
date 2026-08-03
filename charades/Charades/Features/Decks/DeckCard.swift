import SwiftUI

/// Deste kartı — 01-tasarim-sistemi.md §4 anatomisi, ölçüler
/// `ornek-ekranlar.html` `.deck*` kurallarından (mockup 1:1 pt ölçeğinde).
///
/// Kapak amblemi şeffaf PNG (§01 §5): zemin görselin içinde değil, burada
/// bölümün baskın tonundan çiziliyor. Kilitli hâlde sepya yalnızca amblemi ve
/// başlık şeridini etkiliyor, altın çerçeve ve mühür üstte net kalıyor.
struct DeckCard: View {
    let deck: DeckDef
    var isSelected: Bool
    var isLocked: Bool
    /// §05 §4: bugünün bedava destesi — kilidi açık ama kalıcı ücretsiz değil.
    var isDailyFree: Bool
    var cardCount: Int?
    /// §05 §1 + §04 §1: `Canlandır` modu seçiliyken `describe` desteler
    /// soluklaşıp `ANLATMA DESTESİ` etiketi alıyor. Kilit **değil** — seçilebilir
    /// kalıyor, kullanıcı yalnızca ne aldığını biliyor.
    var isOffMode: Bool = false
    /// §05 §6: Mix kurulumunda seçili kartlar onay yerine **kaçıncı sırada**
    /// seçildiklerini gösteriyor — karışım göstergesindeki renk sırası bu.
    var selectionOrder: Int?
    /// Ana ızgarada kilit/ücretsiz rozetleri kapalı: tüm kartlar aktif görünür,
    /// premium bilgisi deste detayında (§ kullanıcı tercihi).
    var showsAccessState: Bool = true
    /// Favori yıldızı — ızgarada durum okunaklı kalsın diye.
    var isFavorite: Bool = false

    @Environment(LocalizationManager.self) private var l10n

    private var visuallyLocked: Bool { showsAccessState && isLocked }

    var body: some View {
        ZStack {
            poster
                // §04 anatomi: kilitli görsel sepia + karartma. Filtre yalnızca
                // afiş katmanına uygulanıyor.
                .saturation(visuallyLocked ? 0.3 : 1)
                .brightness(visuallyLocked ? -0.22 : 0)
                .colorMultiply(visuallyLocked ? Color(hex: 0xC9A98A) : .white)

            if visuallyLocked {
                lockLayer
            }

            reelTag
            ribbon
            if isFavorite {
                favoriteMark
            }
        }
        .padding(5)
        // Kilitli kartın sepyası kadar sert değil: bu bir engel değil uyarı.
        .opacity(isOffMode && !visuallyLocked ? 0.62 : 1)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.surfaceCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 14).strokeBorder(
                        isSelected ? AppColors.accentAmber : AppColors.accentGold.opacity(0.38),
                        lineWidth: isSelected ? 2 : 1
                    )
                }
        }
        // §04: seçili kartın ampul dizisi yanıyor.
        .overlay {
            if isSelected {
                BulbFrame(countPerEdge: 6, diameter: 3, color: AppColors.accentAmber)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 3)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.55), radius: 8, y: 5)
        .shadow(color: AppColors.accentAmber.opacity(isSelected ? 0.28 : 0), radius: 11, y: 6)
        .scaleEffect(isSelected ? 1.03 : 1)
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isSelected)
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Katmanlar

    private var poster: some View {
        VStack(spacing: 0) {
            art
            titleStrip
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(AppColors.accentGold.opacity(0.3), lineWidth: 1)
        }
    }

    private var art: some View {
        ZStack {
            deck.section.artGradient
            HalftoneTexture(dotSize: 0.7, spacing: 4, color: .black.opacity(0.65))
                .opacity(0.2)

            // §05 §1: amblem art alanının %80 genişliğinde ortalanıyor.
            GeometryReader { geometry in
                Image(deck.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width * 0.8)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .overlay(alignment: .leading) { edgeSprockets }
        .overlay(alignment: .trailing) { edgeSprockets }
        // Etiket başlık şeridinin değil afiş alanının altına oturuyor; şeridin
        // üstünde deste adını kapatıyordu.
        .overlay(alignment: .bottomLeading) {
            if isOffMode, !visuallyLocked {
                offModeTag.padding(7)
            }
        }
        // Seçim rozeti de aynı sebeple afiş alanının içinde: 3 kolonlu Mix
        // ızgarasında şeridin üstündeyken deste adının son harfini yiyordu.
        .overlay(alignment: .bottomTrailing) {
            if isSelected {
                selectionTick.padding(7)
            }
        }
    }

    /// §03 "Film şeridi (sprocket)" — deste kartı kenarı.
    private var edgeSprockets: some View {
        SprocketStrip(
            axis: .vertical,
            holeSize: 3,
            spacing: 7,
            holeColor: AppColors.bgFilmBlack.opacity(0.55)
        )
        .padding(.vertical, 6)
    }

    private var titleStrip: some View {
        VStack(spacing: 2) {
            Text(l10n.t(deck.titleKey))
                .font(AppFont.accent(13, weight: .black))
                .lineSpacing(-1)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .foregroundStyle(AppColors.textOnPoster)

            if let cardCount {
                Text(l10n.t("deck.cardCount", count: cardCount))
                    .font(AppFont.ui(7.5, weight: .semibold))
                    .appTracking(1.3)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textOnPosterMuted)
            }
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
            .overlay {
                HalftoneTexture(dotSize: 0.5, spacing: 3, color: AppColors.surfaceCard.opacity(0.5))
                    .opacity(0.14)
            }
        }
    }

    /// §04: sol üst köşede `REEL No. 07`.
    ///
    /// Köşe rozetleri (makara no, kurdele, `describe` etiketi) afişin üzerine
    /// basılmış mürekkep; Dynamic Type ile büyüyünce kapağın dörtte birini
    /// kaplayıp birbirinin üstüne biniyorlar. Taşıdıkları bilgi kartın
    /// erişilebilirlik etiketinde zaten var (§7).
    private var reelTag: some View {
        Text(l10n.t("deck.reel", ["no": deck.reelLabel]))
            .font(AppFont.ui(6.5, weight: .bold, scales: nil))
            .appTracking(1)
            .textCase(.uppercase)
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

    @ViewBuilder
    private var ribbon: some View {
        if let ribbonKey {
            Text(l10n.t(ribbonKey))
                .font(AppFont.ui(6.5, weight: .bold, scales: nil))
                .appTracking(1)
                .textCase(.uppercase)
                .foregroundStyle(isDailyFree ? AppColors.textOnAmber : Color(hex: 0xEAF5EA))
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isDailyFree ? AppColors.accentAmber : AppColors.stateCorrect)
                }
                .padding(9)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }

    /// Favori rozeti — kurdele yokken sağ üstte, varken onun altında değil
    /// afiş köşesinde kalır; ribbon varsa sol alt yerine sağ üst ribbon'ın
    /// yerini bırakıp art alanının sağ altına yakın küçük yıldız.
    private var favoriteMark: some View {
        Image(systemName: "star.fill")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(AppColors.accentAmber)
            .padding(6)
            .background {
                Circle()
                    .fill(AppColors.bgFilmBlack.opacity(0.72))
                    .overlay {
                        Circle().strokeBorder(AppColors.accentAmber.opacity(0.55), lineWidth: 0.5)
                    }
            }
            .padding(9)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: ribbonKey == nil ? .topTrailing : .bottomLeading
            )
            .accessibilityHidden(true)
    }

    /// Kalıcı ücretsiz / bugün bedava yalnızca `showsAccessState` açıkken.
    /// Ana ızgarada gizlenir; `YENİ` rozeti kalır.
    private var ribbonKey: String? {
        if showsAccessState {
            if isDailyFree { return "deck.dailyFree.badge" }
            if deck.isFree { return "deck.free.badge" }
        }
        if deck.isNew() { return "deck.new.badge" }
        return nil
    }

    private var offModeTag: some View {
        Text(l10n.t("deck.describeOnly.badge"))
            .font(AppFont.ui(6.5, weight: .bold, scales: nil))
            .appTracking(1)
            .textCase(.uppercase)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(AppColors.accentGold)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.bgFilmBlack.opacity(0.82))
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(AppColors.accentGold.opacity(0.45), lineWidth: 0.5)
                    }
            }
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

    private var selectionTick: some View {
        Group {
            if let selectionOrder {
                Text("\(selectionOrder)")
                    .font(AppFont.display(12, weight: .bold))
                    .monospacedDigit()
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
            }
        }
            .foregroundStyle(AppColors.textOnAmber)
            .frame(width: 20, height: 20)
            .background(Circle().fill(AppColors.accentAmber))
            .shadow(color: AppColors.accentAmber.opacity(0.75), radius: 6)
    }

    private var accessibilityLabel: String {
        var parts = [l10n.t(deck.titleKey)]
        if let cardCount { parts.append(l10n.t("deck.cardCount", count: cardCount)) }
        if let selectionOrder { parts.append(l10n.t("mix.selection.order", ["order": "\(selectionOrder)"])) }
        if showsAccessState, isLocked { parts.append(l10n.t("deck.locked.stamp")) }
        if isOffMode, !visuallyLocked { parts.append(l10n.t("deck.describeOnly.badge")) }
        if let ribbonKey, !visuallyLocked { parts.append(l10n.t(ribbonKey)) }
        if isFavorite { parts.append(l10n.t("deck.favorite")) }
        return parts.joined(separator: ", ")
    }
}

/// Mockup'taki `.art::after` / `.deck-strip::before` serigrafi noktası —
/// kapak amblemlerinin halftone dokusunu zemine kadar taşıyor.
///
/// Tek nokta deseni `Canvas` ile çizilseydi 3:4 kart başına ~2.500 daire
/// ederdi ve ızgarada altı kart aynı anda görünüyor. Onun yerine bir kez
/// üretilen tek gözlü bir bitmap döşeniyor.
struct HalftoneTexture: View {
    var dotSize: CGFloat = 0.7
    var spacing: CGFloat = 4
    var color: Color = .black

    var body: some View {
        Image(uiImage: Self.tile(dotSize: dotSize, spacing: spacing))
            .resizable(resizingMode: .tile)
            .foregroundStyle(color)
            .allowsHitTesting(false)
    }

    @MainActor private static var cache: [String: UIImage] = [:]

    @MainActor
    private static func tile(dotSize: CGFloat, spacing: CGFloat) -> UIImage {
        let key = "\(dotSize)-\(spacing)"
        if let cached = cache[key] { return cached }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: spacing, height: spacing))
        let image = renderer.image { context in
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(
                in: CGRect(x: 0, y: 0, width: dotSize * 2, height: dotSize * 2)
            )
        }
        .withRenderingMode(.alwaysTemplate)

        cache[key] = image
        return image
    }
}

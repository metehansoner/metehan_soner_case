import SwiftUI

/// Afiş duvarı — 03-onboarding-paywall.md §2 madde 1, `paywall.html` `.collage`.
///
/// Kapaklar **gerçek deste kapaklarından** diziliyor. Kolonlar farklı hızda,
/// ortadakiler ters yönde; alt kenar kadife perdeye karışıyor.
///
/// Kayma `TimelineView` içinde şeridi yeniden çizmiyor: afişler bir kez kuruluyor,
/// yalnızca `offset` güncelleniyor. Aksi hâlde 60 fps'te Image decode yarım
/// kalıyor ve duvarda yalnız başlık şeritleri görünüyordu.
struct PosterWall: View {
    var decks: [DeckDef]
    /// Varyant B'de duvar geri çekiliyor, öndeki bağlam kapağı öne çıkıyor.
    var opacity: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// `paywall.html`: 4 kolon. Tempo biraz yavaş — vitrin, kaydırma çubuğu değil.
    private static let durations: [Double] = [48, 60, 54, 66]
    private static let columnCount = 4

    var body: some View {
        GeometryReader { geometry in
            let gaps = CGFloat(Self.columnCount - 1) * 7
            let columnWidth = max(geometry.size.width - 20 - gaps, 0) / CGFloat(Self.columnCount)

            HStack(spacing: 7) {
                ForEach(0..<Self.columnCount, id: \.self) { index in
                    PosterColumn(
                        decks: slice(index),
                        width: columnWidth,
                        duration: Self.durations[index],
                        isReversed: index == 1 || index == 3,
                        isAnimated: !reduceMotion
                    )
                }
            }
            .padding(.horizontal, 10)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .rotationEffect(.degrees(-3), anchor: UnitPoint(x: 0.5, y: 0.4))
            .scaleEffect(1.07, anchor: UnitPoint(x: 0.5, y: 0.4))
        }
        .clipped()
        .opacity(opacity)
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.7),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Mockup kolon başına 7 afiş; fazlası şeridi ağırlaştırıyor.
    private func slice(_ index: Int) -> [DeckDef] {
        let stride = decks.enumerated().compactMap {
            $0.offset % Self.columnCount == index ? $0.element : nil
        }
        let pool = stride.isEmpty ? decks : stride
        return Array(pool.prefix(7))
    }
}

// MARK: - Kolon

private struct PosterColumn: View {
    let decks: [DeckDef]
    let width: CGFloat
    let duration: Double
    let isReversed: Bool
    let isAnimated: Bool

    /// Duvar saatiyle açılış ofseti — paywall açılınca kayma **sıfırdan**
    /// başlamıyor, zaten akıyormuş gibi duruyor.
    @State private var drift: CGFloat

    private var posterHeight: CGFloat { width * 4 / 3 }
    private var halfHeight: CGFloat {
        CGFloat(decks.count) * (posterHeight + 7)
    }

    init(
        decks: [DeckDef],
        width: CGFloat,
        duration: Double,
        isReversed: Bool,
        isAnimated: Bool
    ) {
        self.decks = decks
        self.width = width
        self.duration = duration
        self.isReversed = isReversed
        self.isAnimated = isAnimated
        let half = CGFloat(decks.count) * (width * 4 / 3 + 7)
        _drift = State(initialValue: Self.offset(
            at: .now,
            duration: duration,
            halfHeight: half,
            isReversed: isReversed
        ))
    }

    var body: some View {
        // `.equatable()` — yalnız `drift` değişince şerit yeniden çizilmesin.
        PosterStrip(decks: decks, width: width, posterHeight: posterHeight)
            .equatable()
            .offset(y: drift)
            .frame(width: width, alignment: .top)
            .onChange(of: width) { _, newWidth in
                // GeometryReader ilk karede 0 verebiliyor; @State o anki ofseti
                // koruyor. Genişlik oturunca duvar saatine göre yeniden tohumla.
                guard newWidth > 1 else { return }
                drift = Self.offset(
                    at: .now,
                    duration: duration,
                    halfHeight: CGFloat(decks.count) * (newWidth * 4 / 3 + 7),
                    isReversed: isReversed
                )
            }
            .task(id: "\(isAnimated)-\(Int(width))") {
                guard isAnimated, width > 1 else { return }
                // ~30 fps yeterli; 60 fps Image/Halftone'u boğuyordu.
                while !Task.isCancelled {
                    drift = Self.offset(
                        at: .now,
                        duration: duration,
                        halfHeight: halfHeight,
                        isReversed: isReversed
                    )
                    try? await Task.sleep(for: .milliseconds(33))
                }
            }
    }

    private static func offset(
        at date: Date,
        duration: Double,
        halfHeight: CGFloat,
        isReversed: Bool
    ) -> CGFloat {
        guard halfHeight > 0, duration > 0 else { return 0 }
        let progress = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: duration) / duration
        let travel = halfHeight * progress
        return isReversed ? travel - halfHeight : -travel
    }
}

/// Sabit şerit. `Equatable` sayesinde ebeveyn ofset güncellemesi gövdeyi
/// yeniden kurmuyor — kapak PNG'leri bir kez decode edilip kalıyor.
private struct PosterStrip: View, Equatable {
    let decks: [DeckDef]
    let width: CGFloat
    let posterHeight: CGFloat

    private var loop: [DeckDef] { decks + decks }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.width == rhs.width
            && lhs.posterHeight == rhs.posterHeight
            && lhs.decks.map(\.id) == rhs.decks.map(\.id)
    }

    var body: some View {
        VStack(spacing: 7) {
            ForEach(Array(loop.enumerated()), id: \.offset) { _, deck in
                DeckMiniPoster(deck: deck)
                    .frame(width: width, height: posterHeight)
            }
        }
    }
}

// MARK: - Mini afiş

/// Ana ekrandaki deste kartının küçültülmüş hâli — `paywall.html` `.mini`.
///
/// HTML anatomisi: dış 3:4 kutu → 3pt pad → esnek art + sabit şerit.
/// `GeometryReader` + `maxHeight: .infinity` burada çöküyordu (yalnız şerit
/// kalıyordu); art alanı `layoutPriority` ile sabit oranlı.
struct DeckMiniPoster: View {
    let deck: DeckDef

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                deck.section.artGradient
                HalftoneTexture(dotSize: 0.7, spacing: 3, color: .black.opacity(0.65))
                    .opacity(0.2)
                Image(deck.imageName)
                    .resizable()
                    .scaledToFit()
                    // HTML: amblem art alanının ~%62'si.
                    .padding(.horizontal, 19)
                    .padding(.vertical, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)

            Text(l10n.t(deck.titleKey))
                .font(AppFont.accent(6, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(AppColors.textOnPoster)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 3)
                .padding(.top, 2.5)
                .padding(.bottom, 3)
                .background {
                    LinearGradient(
                        colors: [AppColors.surfacePoster, AppColors.surfaceTicket],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(AppColors.accentGold.opacity(0.28), lineWidth: 0.5)
        }
        .padding(3)
        .background {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(AppColors.surfaceCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(AppColors.accentGold.opacity(0.34), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.5), radius: 6, y: 4)
    }
}

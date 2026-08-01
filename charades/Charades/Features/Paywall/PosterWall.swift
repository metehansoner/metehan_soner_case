import SwiftUI

/// Afiş duvarı — 03-onboarding-paywall.md §2 madde 1, `paywall.html` `.collage`.
///
/// Kapaklar **gerçek deste kapaklarından** diziliyor, statik bir kolaj değil:
/// "burada çok şey var" mesajı fayda listesiyle değil görüntüyle veriliyor.
/// Kolonlar farklı hızda, ortadaki ters yönde akıyor; alt kenar kadife perdeye
/// karışıyor.
struct PosterWall: View {
    var decks: [DeckDef]
    /// Varyant B'de duvar geri çekiliyor, öndeki bağlam kapağı öne çıkıyor.
    var opacity: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// §2: 26–34 sn döngü, ortadaki ters yönde.
    private static let durations: [Double] = [30, 38, 34]

    var body: some View {
        GeometryReader { geometry in
            let columnWidth = (geometry.size.width - 14 - 20) / 3

            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { index in
                    PosterColumn(
                        decks: slice(index),
                        width: columnWidth,
                        duration: Self.durations[index],
                        isReversed: index == 1,
                        isAnimated: !reduceMotion
                    )
                }
            }
            .padding(.horizontal, 10)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .rotationEffect(.degrees(-3))
            .scaleEffect(1.07)
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

    /// Her kolon farklı destelerle dolsun diye üçe bölünüyor; aynı kapağın iki
    /// kolonda yan yana gelmesi duvarın "çok içerik" iddiasını zayıflatıyor.
    private func slice(_ index: Int) -> [DeckDef] {
        let stride = decks.enumerated().compactMap { $0.offset % 3 == index ? $0.element : nil }
        return stride.isEmpty ? decks : stride
    }
}

private struct PosterColumn: View {
    let decks: [DeckDef]
    let width: CGFloat
    let duration: Double
    let isReversed: Bool
    let isAnimated: Bool

    @State private var isDrifting = false

    /// Kesintisiz döngü için liste iki kez diziliyor ve yarı yüksekliğe kadar
    /// kayıyor: başa dönüş görünmüyor.
    private var loop: [DeckDef] { decks + decks }
    private var posterHeight: CGFloat { width * 4 / 3 }
    private var halfHeight: CGFloat {
        CGFloat(decks.count) * (posterHeight + 7)
    }

    var body: some View {
        VStack(spacing: 7) {
            ForEach(Array(loop.enumerated()), id: \.offset) { _, deck in
                DeckMiniPoster(deck: deck).frame(width: width, height: posterHeight)
            }
        }
        .offset(y: offset)
        .frame(width: width, alignment: .top)
        .onAppear {
            guard isAnimated else { return }
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                isDrifting = true
            }
        }
    }

    private var offset: CGFloat {
        guard isAnimated else { return isReversed ? -halfHeight / 2 : 0 }
        let travel = isDrifting ? halfHeight : 0
        return isReversed ? travel - halfHeight : -travel
    }
}

/// Ana ekrandaki deste kartının küçültülmüş hâli — `paywall.html` `.mini`.
/// Kart kromu (makara etiketi, mühür, seçim rozeti) yok: duvarda okunmuyor,
/// yalnızca gürültü ekliyor.
struct DeckMiniPoster: View {
    let deck: DeckDef

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                deck.section.artGradient
                HalftoneTexture(dotSize: 0.7, spacing: 3, color: .black.opacity(0.65))
                    .opacity(0.2)
                GeometryReader { geometry in
                    Image(deck.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * 0.62)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }

            Text(l10n.t(deck.titleKey))
                .font(AppFont.accent(6, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(AppColors.accentGold.opacity(0.28), lineWidth: 0.5)
        }
        .padding(3)
        .background {
            RoundedRectangle(cornerRadius: 9)
                .fill(AppColors.surfaceCard)
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(AppColors.accentGold.opacity(0.34), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.5), radius: 6, y: 4)
    }
}

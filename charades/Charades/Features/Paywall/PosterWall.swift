import SwiftUI


struct PosterWall: View {
    var decks: [DeckDef]

    var opacity: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion


    private static let durations: [Double] = [56, 68, 60]
    private static let columnCount = 3

    var body: some View {
        GeometryReader { geometry in
            let gaps = CGFloat(Self.columnCount - 1) * 8
            let columnWidth = max(geometry.size.width - 16 - gaps, 0) / CGFloat(Self.columnCount)

            HStack(spacing: 8) {
                ForEach(0..<Self.columnCount, id: \.self) { index in
                    PosterColumn(
                        decks: slice(index),
                        width: columnWidth,
                        duration: Self.durations[index],
                        isReversed: index == 1,
                        isAnimated: !reduceMotion
                    )
                }
            }
            .padding(.horizontal, 8)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .rotationEffect(.degrees(-3), anchor: UnitPoint(x: 0.5, y: 0.4))
            .scaleEffect(1.08, anchor: UnitPoint(x: 0.5, y: 0.4))
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


    private func slice(_ index: Int) -> [DeckDef] {
        let stride = decks.enumerated().compactMap {
            $0.offset % Self.columnCount == index ? $0.element : nil
        }
        let pool = stride.isEmpty ? decks : stride
        return Array(pool.prefix(6))
    }
}


private struct PosterColumn: View {
    let decks: [DeckDef]
    let width: CGFloat
    let duration: Double
    let isReversed: Bool
    let isAnimated: Bool


    @State private var offsetY: CGFloat = 0

    private var posterHeight: CGFloat { width * 4 / 3 }
    private var halfHeight: CGFloat {
        CGFloat(decks.count) * (posterHeight + 7)
    }

    private var animationID: String {
        "\(isAnimated)-\(Int(width.rounded()))-\(decks.count)-\(isReversed)"
    }

    var body: some View {
        PosterStrip(decks: decks, width: width, posterHeight: posterHeight)
            .equatable()
            .drawingGroup(opaque: false)
            .offset(y: offsetY)
            .frame(width: width, alignment: .top)
            .task(id: animationID) { await runMarquee() }
    }

    @MainActor
    private func runMarquee() async {
        guard width > 1, halfHeight > 0 else { return }

        let start = Self.offset(
            at: .now,
            duration: duration,
            halfHeight: halfHeight,
            isReversed: isReversed
        )

        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) { offsetY = start }

        guard isAnimated else { return }


        await Task.yield()
        guard !Task.isCancelled else { return }


        let end = isReversed ? start + halfHeight : start - halfHeight
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            offsetY = end
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
                DeckMiniPoster(deck: deck, showsHalftone: false)
                    .frame(width: width, height: posterHeight)
            }
        }
    }
}


struct DeckMiniPoster: View {
    let deck: DeckDef


    var showsHalftone: Bool = true

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let titleSize = max(10, min(14, w * 0.1))
            let artPad = max(10, w * 0.11)
            let stripPadH = max(5, w * 0.06)
            let corner = max(7, w * 0.07)

            VStack(spacing: 0) {
                ZStack {
                    deck.section.artGradient
                    if showsHalftone {
                        HalftoneTexture(dotSize: 0.7, spacing: 3, color: .black.opacity(0.65))
                            .opacity(0.2)
                    }
                    Image(deck.imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(artPad)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)

                Text(l10n.t(deck.titleKey))
                    .font(AppFont.accent(titleSize, weight: .black))
                    .lineSpacing(-1)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(AppColors.textOnPoster)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, stripPadH)
                    .padding(.top, max(4, w * 0.04))
                    .padding(.bottom, max(5, w * 0.045))
                    .background {
                        LinearGradient(
                            colors: [AppColors.surfacePoster, AppColors.surfaceTicket],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: corner * 0.7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: corner * 0.7, style: .continuous)
                    .strokeBorder(AppColors.accentGold.opacity(0.28), lineWidth: 0.5)
            }
            .padding(max(3, w * 0.03))
            .background {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(AppColors.surfaceCard)
                    .overlay {
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .strokeBorder(AppColors.accentGold.opacity(0.34), lineWidth: 1)
                    }
            }
            .shadow(color: .black.opacity(0.5), radius: 6, y: 4)
        }
    }
}

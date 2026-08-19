import SwiftUI


struct FilterChipRow: View {
    @Binding var selection: DeckFilter
    var favoriteCount: Int
    var date: Date = .now

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion


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
                HStack(spacing: 10) {
                    ForEach(filters) { filter in
                        FilterChip(
                            filter: filter,
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
                .padding(.vertical, 8)
            }


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
    let filter: DeckFilter
    let title: String
    let isActive: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.symbolName)
                    .font(.system(size: 13, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isActive ? filter.chipLabelColor : filter.chipAccent)

                Text(title)
                    .font(AppFont.display(14, weight: .semibold))
                    .appTracking(0.7)
                    .textCase(.uppercase)
                    .foregroundStyle(isActive ? filter.chipLabelColor : AppColors.textCream)
                    .lineLimit(1)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 11)
            .background {
                Capsule()
                    .fill(isActive ? AnyShapeStyle(filter.chipFill) : AnyShapeStyle(idleFill))
                    .overlay {
                        Capsule().strokeBorder(
                            isActive ? filter.chipAccent.opacity(0.95) : AppColors.accentGold.opacity(0.5),
                            lineWidth: isActive ? 1.6 : 1.15
                        )
                    }
            }
            .overlay {
                if isActive {
                    TwinkleStarFrame(color: filter.chipBulbColor)
                }
            }
            .shadow(
                color: filter.chipAccent.opacity(isActive ? 0.38 : 0.12),
                radius: isActive ? 8 : 4,
                y: isActive ? 2 : 1
            )
            .scaleEffect(isActive && !reduceMotion ? 1.03 : 1)
            .contentShape(Capsule())
            .tapTarget()
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.72), value: isActive)
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }

    private var idleFill: LinearGradient {
        LinearGradient(
            colors: [AppColors.surfaceCardRaised, AppColors.surfaceCard],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct TwinkleStarFrame: View {
    var color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let stars: [(x: CGFloat, y: CGFloat, size: CGFloat, phase: Double)] = [
        (0.10, 0.16, 5.5, 0.00),
        (0.90, 0.22, 4.5, 0.38),
        (0.86, 0.86, 5, 0.62),
        (0.12, 0.82, 4.5, 0.84),
    ]

    var body: some View {
        GeometryReader { geo in
            if reduceMotion || ThermalMonitor.shared.isThrottled {
                starLayer(in: geo.size) { _ in 0.45 }
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 10)) { context in
                    let time = context.date.timeIntervalSinceReferenceDate
                    starLayer(in: geo.size) { phase in
                        Self.twinkle(at: time, phase: phase)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func starLayer(in size: CGSize, level: @escaping (Double) -> Double) -> some View {
        ZStack {
            ForEach(Array(stars.enumerated()), id: \.offset) { _, star in
                let t = level(star.phase)
                Image(systemName: "sparkle")
                    .font(.system(size: star.size, weight: .semibold))
                    .foregroundStyle(color)
                    .opacity(0.18 + 0.52 * t)
                    .scaleEffect(0.85 + 0.2 * t)
                    .shadow(color: color.opacity(t * 0.45), radius: 1.5 + 1.5 * t)
                    .position(x: size.width * star.x, y: size.height * star.y)
            }
        }
    }

    private static func twinkle(at time: TimeInterval, phase: Double) -> Double {
        let period = 1.85
        var p = (time / period + phase).truncatingRemainder(dividingBy: 1)
        if p < 0 { p += 1 }
        let wave = 0.5 + 0.5 * cos(2 * .pi * p)
        return pow(wave, 1.25)
    }
}

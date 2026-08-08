import SwiftUI


struct FilmStripProgress: View {
    var total: Int
    var current: Int
    var onSelect: ((Int) -> Void)?

    var body: some View {
        VStack(spacing: 3) {
            SprocketStrip(holeSize: 3.5, spacing: 5, holeColor: AppColors.accentGold.opacity(0.45))

            HStack(spacing: 4) {
                ForEach(0..<max(total, 1), id: \.self) { index in
                    frame(at: index)
                }
            }

            SprocketStrip(holeSize: 3.5, spacing: 5, holeColor: AppColors.accentGold.opacity(0.45))
        }
        .animation(.easeOut(duration: 0.2), value: current)
    }

    @ViewBuilder
    private func frame(at index: Int) -> some View {
        let isCurrent = index == current
        let isDone = index < current
        let cell = RoundedRectangle(cornerRadius: 2)
            .fill(fill(isCurrent: isCurrent, isDone: isDone))
            .overlay {
                RoundedRectangle(cornerRadius: 2).strokeBorder(
                    AppColors.accentGold.opacity(isCurrent ? 0.9 : 0.3),
                    lineWidth: 1
                )
            }
            .frame(height: 7)

        if let onSelect, isDone {
            Button { onSelect(index) } label: {
                cell


                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                    .padding(.vertical, -14)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: "\(index + 1)"))
        } else {
            cell
        }
    }

    private func fill(isCurrent: Bool, isDone: Bool) -> Color {
        if isCurrent { return AppColors.accentAmber }
        return isDone ? AppColors.accentGold : AppColors.surfaceCardRaised
    }
}


struct SprocketStrip: View {
    var axis: Axis = .horizontal
    var holeSize: CGFloat = 7
    var spacing: CGFloat = 7
    var holeColor: Color = AppColors.bgFilmBlack

    var body: some View {
        Canvas { context, size in
            let length = axis == .horizontal ? size.width : size.height
            let breadth = axis == .horizontal ? size.height : size.width
            let step = holeSize + spacing
            let count = max(1, Int((length + spacing) / step))
            let used = CGFloat(count) * step - spacing

            var offset = (length - used) / 2
            let cross = (breadth - holeSize) / 2

            for _ in 0..<count {
                let origin = axis == .horizontal
                    ? CGPoint(x: offset, y: cross)
                    : CGPoint(x: cross, y: offset)
                context.fill(
                    Path(
                        roundedRect: CGRect(origin: origin, size: CGSize(width: holeSize, height: holeSize)),
                        cornerRadius: holeSize * 0.28
                    ),
                    with: .color(holeColor)
                )
                offset += step
            }
        }
        .frame(
            width: axis == .vertical ? holeSize + 4 : nil,
            height: axis == .horizontal ? holeSize + 4 : nil
        )
        .allowsHitTesting(false)
    }
}

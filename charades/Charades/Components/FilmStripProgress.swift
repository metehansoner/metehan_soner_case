import SwiftUI

/// Film şeridi ilerleme göstergesi — 01-tasarim-sistemi.md §6.2:
/// sayfa sayısına göre uzuyor, o yüzden statik görsel değil komponent.
/// Onboarding ve Nasıl Oynanır slider'ının sayfa göstergesi bu.
struct FilmStripProgress: View {
    var total: Int
    var current: Int

    var body: some View {
        VStack(spacing: 3) {
            SprocketStrip(holeSize: 3.5, spacing: 5, holeColor: AppColors.accentGold.opacity(0.45))

            HStack(spacing: 4) {
                ForEach(0..<max(total, 1), id: \.self) { index in
                    let isCurrent = index == current
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isCurrent ? AppColors.accentAmber : AppColors.surfaceCardRaised)
                        .overlay {
                            RoundedRectangle(cornerRadius: 2).strokeBorder(
                                AppColors.accentGold.opacity(isCurrent ? 0.9 : 0.3),
                                lineWidth: 1
                            )
                        }
                        .frame(height: 7)
                }
            }

            SprocketStrip(holeSize: 3.5, spacing: 5, holeColor: AppColors.accentGold.opacity(0.45))
        }
        .animation(.easeOut(duration: 0.2), value: current)
    }
}

/// §3 "Film şeridi (sprocket)": kenarda tekrarlayan yuvarlatılmış kare deliği.
/// Deste kartı kenarı, oyun kartının üst/alt bandı ve tur sonu ekranı kullanıyor.
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

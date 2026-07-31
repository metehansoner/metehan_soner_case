import SwiftUI

enum AppColors {
    // Vivid Ocean — matched to `palette_preview_home_vivid.png`
    // Bright electric blue stage (not muddy navy).

    static let bgPrimary = Color(hex: 0x0047E8)
    static let bgPrimaryMid = Color(hex: 0x1A6BFF)
    static let bgPrimaryTop = Color(hex: 0x3D8BFF)
    static let bgGlow = Color(hex: 0x66B3FF)
    static let bgGlowCyan = Color(hex: 0x00E5FF)
    static let bgGrid = Color(hex: 0xA8D4FF).opacity(0.22)

    static let surfaceCard = Color(hex: 0x001A4D)
    static let surfaceCardElevated = Color(hex: 0x0A2F7A)
    static let surfaceCanvas = Color(hex: 0xF4F7FB)

    static let accentCyan = Color(hex: 0x00F0FF)
    static let accentCyanDeep = Color(hex: 0x00C8E8)
    static let accentBlue = Color(hex: 0x3D7BFF)
    static let accentYellow = Color(hex: 0xFFEF00)

    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0xE8F2FF)
    static let textOnLight = Color(hex: 0x001A4D)

    static let stateSuccess = Color(hex: 0x3DFFB0)
    static let stateDanger = Color(hex: 0xFF5A6A)
    static let stateLocked = Color(hex: 0x8AA4D4)
    static let overlayScrim = Color(hex: 0x001033).opacity(0.5)

    static let btnPrimaryBg = Color(hex: 0xFFE566)
    static let btnPrimaryText = Color(hex: 0x001A4D)
    static let btnSecondaryBg = Color(hex: 0x0A2F7A)
    static let btnDisabledBg = Color(hex: 0x2A4A8C)
    static let btnDisabledText = Color(hex: 0x8AA4D4)

    static var screenGradient: LinearGradient {
        LinearGradient(
            colors: [bgPrimaryTop, bgPrimaryMid, bgPrimary],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var drawCardGradient: LinearGradient {
        LinearGradient(
            colors: [accentCyanDeep, accentBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

struct OceanBackground: View {
    var body: some View {
        ZStack {
            AppColors.screenGradient

            RadialGradient(
                colors: [
                    AppColors.bgGlow.opacity(0.75),
                    AppColors.bgGlow.opacity(0.25),
                    .clear
                ],
                center: .center,
                startRadius: 10,
                endRadius: 380
            )

            RadialGradient(
                colors: [
                    AppColors.bgGlowCyan.opacity(0.28),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.28),
                startRadius: 4,
                endRadius: 260
            )

            TwinklingStarField(stars: Self.starField)

            RadialGradient(
                colors: [.clear, Color.black.opacity(0.18)],
                center: .center,
                startRadius: 180,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }

    private static let starField: [TwinkleStar] = {
        var stars: [TwinkleStar] = []
        stars.append(contentsOf: TwinkleStar.make(seed: 11, count: 72, tint: .white, baseOpacity: 0.34))
        stars.append(contentsOf: TwinkleStar.make(seed: 29, count: 48, tint: AppColors.accentYellow, baseOpacity: 0.26))
        stars.append(contentsOf: TwinkleStar.make(seed: 47, count: 40, tint: AppColors.accentCyan, baseOpacity: 0.24))
        stars.append(contentsOf: TwinkleStar.make(seed: 73, count: 28, tint: .white, baseOpacity: 0.18))
        return stars
    }()
}

private struct TwinkleStar: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let phase: Double
    let speed: Double
    let tint: Color
    let baseOpacity: Double

    static func make(seed: UInt64, count: Int, tint: Color, baseOpacity: Double) -> [TwinkleStar] {
        var rng = StarRNG(seed: seed)
        return (0..<count).map { index in
            TwinkleStar(
                id: Int(seed) * 1000 + index,
                x: CGFloat(rng.nextUnit()),
                y: CGFloat(rng.nextUnit()),
                size: 1.2 + CGFloat(rng.nextUnit()) * 3.2,
                phase: rng.nextUnit() * .pi * 2,
                speed: 0.18 + rng.nextUnit() * 0.35,
                tint: tint,
                baseOpacity: baseOpacity * (0.7 + rng.nextUnit() * 0.6)
            )
        }
    }
}

private struct TwinklingStarField: View {
    let stars: [TwinkleStar]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12.0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            Canvas { canvas, size in
                for star in stars {
                    let wave = sin(time * star.speed + star.phase)
                    let soft = 0.5 + 0.5 * wave
                    let spark = pow(max(0, wave), 16) * 0.22
                    let opacity = min(1, star.baseOpacity * (0.72 + 0.28 * soft) + spark)
                    let center = CGPoint(x: star.x * size.width, y: star.y * size.height)
                    let drawSize = star.size * (1 + spark * 0.2)

                    if spark > 0.12 {
                        let glow = Path(ellipseIn: CGRect(
                            x: center.x - drawSize * 1.3,
                            y: center.y - drawSize * 1.3,
                            width: drawSize * 2.6,
                            height: drawSize * 2.6
                        ))
                        canvas.fill(glow, with: .color(star.tint.opacity(opacity * 0.1)))
                    }

                    canvas.fill(
                        starPath(at: center, size: drawSize),
                        with: .color(star.tint.opacity(opacity))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func starPath(at center: CGPoint, size: CGFloat) -> Path {
        var path = Path()
        let outer = size
        let inner = size * 0.34
        for i in 0..<8 {
            let angle = (CGFloat(i) * .pi / 4) - .pi / 2
            let radius = i.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

private struct StarRNG {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func nextUnit() -> Double {
        Double(next() % 10_000) / 10_000
    }
}

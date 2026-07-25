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

            // Center electric spotlight
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

            // Soft cyan wash from upper-mid
            RadialGradient(
                colors: [
                    AppColors.bgGlowCyan.opacity(0.28),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.28),
                startRadius: 4,
                endRadius: 260
            )

            // Imposter Party stage motif — not a generic square grid.
            PartyStagePattern()
                .stroke(
                    LinearGradient(
                        colors: [
                            AppColors.accentCyan.opacity(0.10),
                            Color.white.opacity(0.07),
                            AppColors.accentCyan.opacity(0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
                )

            // Tiny scattered stars
            TinyStars(seed: 11, count: 42)
                .fill(Color.white.opacity(0.28))

            TinyStars(seed: 29, count: 28)
                .fill(AppColors.accentYellow.opacity(0.20))

            TinyStars(seed: 47, count: 22)
                .fill(AppColors.accentCyan.opacity(0.18))

            // Soft vignette so content pops
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.18)],
                center: .center,
                startRadius: 180,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }
}

/// Perspective stage lines — unique to Imposter Party atmosphere.
private struct PartyStagePattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let vanishing = CGPoint(x: rect.midX, y: rect.height * 0.18)

        // Soft horizon arc
        let horizonY = rect.height * 0.42
        path.move(to: CGPoint(x: 0, y: horizonY))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: horizonY),
            control: CGPoint(x: rect.midX, y: horizonY - 18)
        )

        // Perspective rays from vanishing point (lower stage)
        let rayCount = 11
        for i in 0..<rayCount {
            let t = CGFloat(i) / CGFloat(rayCount - 1)
            let bottomX = rect.width * (-0.15 + t * 1.3)
            path.move(to: vanishing)
            path.addLine(to: CGPoint(x: bottomX, y: rect.height + 20))
        }

        // Curved stage rings
        for ring in 1...4 {
            let progress = CGFloat(ring) / 4.5
            let y = horizonY + (rect.height - horizonY) * progress
            let inset = rect.width * (0.42 - progress * 0.38)
            let left = inset
            let right = rect.width - inset
            path.move(to: CGPoint(x: left, y: y))
            path.addQuadCurve(
                to: CGPoint(x: right, y: y),
                control: CGPoint(x: rect.midX, y: y + 10 * (1 - progress))
            )
        }

        return path
    }
}

/// Small 4-point stars with deterministic scatter (looks random, stays stable).
private struct TinyStars: Shape {
    var seed: UInt64
    var count: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var rng = StarRNG(seed: seed)

        for _ in 0..<count {
            let x = CGFloat(rng.nextUnit()) * rect.width
            let y = CGFloat(rng.nextUnit()) * rect.height
            let size = 1.4 + CGFloat(rng.nextUnit()) * 2.4
            path.addPath(Self.star(at: CGPoint(x: x, y: y), size: size))
        }
        return path
    }

    private static func star(at center: CGPoint, size: CGFloat) -> Path {
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

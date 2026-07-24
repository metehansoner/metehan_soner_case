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

    static let btnPrimaryBg = Color.white
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

            // Center electric spotlight (preview look)
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

            GridPattern()
                .stroke(AppColors.bgGrid, lineWidth: 1.1)
        }
        .ignoresSafeArea()
    }
}

private struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 26
        var x: CGFloat = 0
        while x <= rect.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
            x += step
        }
        var y: CGFloat = 0
        while y <= rect.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
            y += step
        }
        return path
    }
}

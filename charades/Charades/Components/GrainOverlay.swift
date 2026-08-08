import CoreGraphics
import SwiftUI


struct GrainOverlay: View {

    var intensity: Double = 0.05

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if isEnabled, !NoiseTiles.frames.isEmpty {
            TimelineView(.animation(minimumInterval: 1.0 / 12)) { context in
                let index = NoiseTiles.index(at: context.date)
                Image(decorative: NoiseTiles.frames[index], scale: 1)
                    .resizable(resizingMode: .tile)
                    .opacity(intensity)
                    .blendMode(.overlay)
            }
            .allowsHitTesting(false)
        }
    }


    private var isEnabled: Bool {
        !reduceTransparency && FilmEffects.decorationsEnabled
    }
}


struct ScanlineOverlay: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if isEnabled {
            Canvas { context, size in
                var y: CGFloat = 0
                while y < size.height {
                    context.fill(
                        Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                        with: .color(.black)
                    )
                    y += 2
                }
            }
            .opacity(0.03)
            .allowsHitTesting(false)
        }
    }

    private var isEnabled: Bool {
        !reduceTransparency && FilmEffects.decorationsEnabled
            && AppSettingsStore.shared.scanlinesEnabled
    }
}

private enum NoiseTiles {
    static let frames: [CGImage] = (0..<3).compactMap { make(seed: 0xC0FFEE &+ UInt64($0)) }

    static func index(at date: Date) -> Int {
        let tick = Int(date.timeIntervalSinceReferenceDate * 12)
        return ((tick % frames.count) + frames.count) % frames.count
    }


    private static func make(seed: UInt64, side: Int = 96) -> CGImage? {
        var state = seed
        func nextByte() -> UInt8 {
            state = state &+ 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return UInt8(truncatingIfNeeded: z ^ (z >> 31))
        }

        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        for i in stride(from: 0, to: pixels.count, by: 4) {
            let value = nextByte()
            pixels[i] = value
            pixels[i + 1] = value
            pixels[i + 2] = value
            pixels[i + 3] = 255
        }

        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(
            width: side,
            height: side,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: side * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}

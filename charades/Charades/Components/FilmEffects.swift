import Observation
import SwiftUI


@MainActor
enum FilmEffects {


    static var decorationsEnabled: Bool {
        AppSettingsStore.shared.filmEffectsEnabled && !ThermalMonitor.shared.isThrottled
    }
}


@MainActor
@Observable
final class ThermalMonitor {
    static let shared = ThermalMonitor()

    private(set) var isThrottled: Bool

    private init() {
        isThrottled = DeviceConditions.isThermallyThrottled
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                ThermalMonitor.shared.isThrottled = DeviceConditions.isThermallyThrottled
            }
        }
    }
}


struct CueMark: View {

    var isActive: Bool
    var diameter: CGFloat = 26

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isVisible = false

    private static let flashes = 3
    private static let flashDuration: TimeInterval = 0.07

    var body: some View {
        Circle()
            .strokeBorder(AppColors.surfacePoster.opacity(0.85), lineWidth: 2)
            .frame(width: diameter, height: diameter)
            .opacity(isVisible ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task(id: isActive) { await flash() }
    }

    private func flash() async {


        guard isActive, FilmEffects.decorationsEnabled else {
            isVisible = false
            return
        }

        if reduceMotion {
            isVisible = true
            try? await Task.sleep(for: .milliseconds(600))
            isVisible = false
            return
        }

        for _ in 0..<Self.flashes {
            isVisible = true
            try? await Task.sleep(for: .seconds(Self.flashDuration))
            isVisible = false
            try? await Task.sleep(for: .seconds(Self.flashDuration))
        }
    }
}


struct ScratchOverlay: View {

    private static let frameRate: Double = 12
    private static let scratchCount = 3
    private static let dustCount = 14

    var body: some View {
        if FilmEffects.decorationsEnabled {
            TimelineView(.animation(minimumInterval: 1 / Self.frameRate)) { context in
                let tick = Int(context.date.timeIntervalSinceReferenceDate * Self.frameRate)
                Canvas { canvas, size in
                    draw(in: &canvas, size: size, tick: tick)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, tick: Int) {
        var seed = UInt64(bitPattern: Int64(tick))

        func next() -> Double {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double((seed >> 33) % 10_000) / 10_000
        }

        for _ in 0..<Self.scratchCount {


            let x = next() * size.width
            let top = next() * size.height * 0.5
            let length = size.height * (0.25 + next() * 0.5)
            var path = Path()
            path.move(to: CGPoint(x: x, y: top))
            path.addLine(to: CGPoint(x: x + next() * 2 - 1, y: min(top + length, size.height)))
            context.stroke(
                path,
                with: .color(.white.opacity(0.05 + next() * 0.05)),
                lineWidth: 0.6 + next() * 0.7
            )
        }

        for _ in 0..<Self.dustCount {
            let point = CGPoint(x: next() * size.width, y: next() * size.height)
            let side = 0.8 + next() * 1.6
            context.fill(
                Path(ellipseIn: CGRect(origin: point, size: CGSize(width: side, height: side))),
                with: .color(.white.opacity(0.05 + next() * 0.08))
            )
        }
    }
}


struct SpotlightSweepModifier: ViewModifier {
    var cornerRadius: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion


    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.42), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.55)
                    .rotationEffect(.degrees(16))
                    .offset(x: phase * geometry.size.width * 1.3)
                    .blendMode(.plusLighter)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .allowsHitTesting(false)
            }
            .task {
                guard !reduceMotion else { return }

                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(.easeInOut(duration: 0.6)) { phase = 1 }
            }
    }
}

extension View {
    func spotlightSweep(cornerRadius: CGFloat) -> some View {
        modifier(SpotlightSweepModifier(cornerRadius: cornerRadius))
    }
}


struct LetterboxBars: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isIn = false


    private func barHeight(for size: CGSize) -> CGFloat {
        let target = size.width / 2.39
        return max(0, (size.height - target) / 2)
    }

    var body: some View {
        GeometryReader { geometry in
            let height = min(barHeight(for: geometry.size), geometry.size.height * 0.14)
            VStack {
                bar(height: height)
                Spacer(minLength: 0)
                bar(height: height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task { await sweep() }
    }

    private func sweep() async {


        guard !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.3)) { isIn = true }
        try? await Task.sleep(for: .milliseconds(750))
        withAnimation(.easeIn(duration: 0.35)) { isIn = false }
    }

    private func bar(height: CGFloat) -> some View {
        AppColors.bgFilmBlack
            .frame(height: isIn ? height : 0)
    }
}

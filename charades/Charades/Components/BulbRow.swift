import SwiftUI

/// Marquee ampulleri — 01-tasarim-sistemi.md §3.
///
/// Nabız 1.5 saniye, her ampul 0.12 saniye gecikmeli başlıyor; dizi boyunca
/// akan bir dalga oluşuyor. §7: Reduce Motion açıkken nabız durur, ampuller
/// sabit yanık kalır.
struct BulbRow: View {
    var count = 9
    var diameter: CGFloat = 5
    var color: Color = AppColors.accentAmber
    var isLit = true
    /// Dalganın kaçıncı ampulden başladığı; üst ve alt sıra kaydırmalı yansın diye.
    var phaseOffset = 0

    var body: some View {
        BulbTimeline { level in
            HStack(spacing: 0) {
                ForEach(0..<max(count, 1), id: \.self) { index in
                    Bulb(
                        diameter: diameter,
                        color: color,
                        level: isLit ? level(index + phaseOffset) : 0
                    )
                    if index < count - 1 {
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }
}

/// Üst ve alt kenara dizilmiş iki sıra — logo plaketi ve birincil buton (§3, §4).
struct BulbFrame: View {
    var countPerEdge = 5
    var diameter: CGFloat = 3.5
    var color: Color = AppColors.surfacePoster
    var isLit = true

    var body: some View {
        VStack {
            BulbRow(count: countPerEdge, diameter: diameter, color: color, isLit: isLit)
            Spacer(minLength: 0)
            BulbRow(
                count: countPerEdge,
                diameter: diameter,
                color: color,
                isLit: isLit,
                phaseOffset: countPerEdge
            )
        }
        .allowsHitTesting(false)
    }
}

/// Dört kenarı saran ampul halkası — splash ikon çerçevesi (`ornek-ekranlar.html`
/// `ringBulbs`). Köşeler iki kez sayılmasın diye yan kenarlar uçları atlar.
struct BulbRing: View {
    var countPerSide = 8
    var diameter: CGFloat = 4
    var color: Color = AppColors.accentAmber
    var isLit = true

    var body: some View {
        GeometryReader { geometry in
            let points = Self.positions(in: geometry.size, perSide: countPerSide)
            BulbTimeline { level in
                ZStack {
                    ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                        Bulb(
                            diameter: diameter,
                            color: color,
                            level: isLit ? level(index) : 0
                        )
                        .position(point)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private static func positions(in size: CGSize, perSide: Int) -> [CGPoint] {
        let n = max(perSide, 2)
        var points: [CGPoint] = []
        for index in 0..<n {
            let t = CGFloat(index) / CGFloat(n - 1)
            points.append(CGPoint(x: t * size.width, y: 0))
            points.append(CGPoint(x: t * size.width, y: size.height))
        }
        for index in 1..<(n - 1) {
            let t = CGFloat(index) / CGFloat(n - 1)
            points.append(CGPoint(x: 0, y: t * size.height))
            points.append(CGPoint(x: size.width, y: t * size.height))
        }
        return points
    }
}

/// Nabız hesabını tek yerde tutar; her ampul kendi `TimelineView`'ını kurmasın diye.
private struct BulbTimeline<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let content: (@escaping (Int) -> Double) -> Content

    var body: some View {
        // §08 §5: nabız süregelen bir efekt — ısınmada sabit yanık kalıyor.
        // Ampuller sönmüyor, yalnızca 12 fps'lik çizim duruyor.
        if reduceMotion || ThermalMonitor.shared.isThrottled {
            content { _ in 1 }
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 12)) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                content { index in Self.level(at: time, index: index) }
            }
        }
    }

    /// 1.5 sn periyot, 1 → 0.34 → 1; ampul başına 0.12 sn gecikme.
    private static func level(at time: TimeInterval, index: Int) -> Double {
        let period = 1.5
        let shifted = time - Double(index) * 0.12
        var phase = shifted.truncatingRemainder(dividingBy: period) / period
        if phase < 0 { phase += 1 }
        return 0.34 + 0.66 * (0.5 + 0.5 * cos(2 * .pi * phase))
    }
}

private struct Bulb: View {
    let diameter: CGFloat
    let color: Color
    /// 0 = sönük (disabled), 1 = tam parlak.
    let level: Double

    var body: some View {
        Circle()
            .fill(level > 0 ? color : AppColors.stateLocked.opacity(0.45))
            .frame(width: diameter, height: diameter)
            .opacity(level > 0 ? level : 1)
            .shadow(
                color: color.opacity(level > 0 ? level * 0.9 : 0),
                radius: diameter * (0.8 + level),
                x: 0,
                y: 0
            )
    }
}

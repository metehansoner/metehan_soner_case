import SwiftUI

/// Ekran 14 — 02-ekran-akisi.md §4, görseli 08-sinematik-detaylar.md A1 /
/// `sinematik-ozellikler.html` A1 · Akademi Geri Sayımı.
///
/// Eski film makarası lideri: krem parchment zemin, iki eşmerkezli daire,
/// artı işareti, 1 saniyede tam tur atan 90° süpürge, ortada büyük mürekkep
/// rakamı. Üstte `CHARADES · REEL NN`, altta `HAZIR OL`.
///
/// §08 §0: **atlanamayan tek animasyon.** Dokunmak kalan süreyi 1 saniyeye
/// indiriyor, sıfırlamıyor.
struct CountdownView: View {
    let value: Int
    /// Arşiv / klaket ile aynı sahne numarası — üst şeritteki REEL.
    let reel: Int
    var onTap: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Son rakamda lambanın tutukluk yapması: 0 = normal, 1 = sönük.
    @State private var flicker: Double = 0
    @State private var numberPulse = false

    private let ink = Color(hex: 0x1C1512)
    private let dialSize: CGFloat = 250

    var body: some View {
        ZStack {
            parchment

            VStack(spacing: 0) {
                Text(reelLabel)
                    .font(AppFont.ui(9, weight: .bold, scales: nil))
                    .appTracking(4)
                    .textCase(.uppercase)
                    .foregroundStyle(ink.opacity(0.5))
                    .padding(.top, 28)

                Spacer(minLength: 0)

                dial

                Spacer(minLength: 0)

                Text(l10n.t("game.countdown.ready"))
                    .font(AppFont.ui(10, weight: .bold, scales: nil))
                    .appTracking(4.5)
                    .textCase(.uppercase)
                    .foregroundStyle(ink.opacity(0.65))
                    .padding(.bottom, 28)
            }
            .padding(.horizontal, 24)

            // Eskimiş kopyanın çizikleri — makaranın kendisi.
            ScratchOverlay()
                .blendMode(.softLight)
                .opacity(0.85)

            // Projektör titremesi: krem zeminde hafif kararma.
            ink.opacity(flicker * 0.22)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value)")
        .task(id: value) {
            await pulseNumber()
            await flickerIfLast()
        }
    }

    // MARK: Zemin

    private var parchment: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color(hex: 0xE8DCC4),
                    Color(hex: 0xC9B998),
                    Color(hex: 0x8A7C62),
                ],
                center: UnitPoint(x: 0.5, y: 0.46),
                startRadius: 0,
                endRadius: 520
            )
            .ignoresSafeArea()

            HalftoneTexture(dotSize: 0.6, spacing: 3, color: ink.opacity(0.5))
                .opacity(0.3)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    private var reelLabel: String {
        // Marka + makara no — mockup'taki `Charades · Reel 07`.
        "Charades · Reel \(String(format: "%02d", reel))"
    }

    // MARK: Dial

    private var dial: some View {
        ZStack {
            sweep

            Circle()
                .strokeBorder(ink.opacity(0.78), lineWidth: 2.5)

            Circle()
                .strokeBorder(ink.opacity(0.55), lineWidth: 1.5)
                .padding(34)

            // Artı: daireyi biraz aşıyor (HTML `top/bottom: -26px`).
            Rectangle()
                .fill(ink.opacity(0.7))
                .frame(width: 1.5)
                .frame(height: dialSize + 52)
            Rectangle()
                .fill(ink.opacity(0.7))
                .frame(height: 1.5)
                .frame(width: dialSize + 52)

            Text("\(value)")
                .textStyle(.leaderNumber)
                .foregroundStyle(ink)
                .shadow(color: Color(hex: 0xFFFCF0).opacity(0.35), radius: 0, y: 3)
                .scaleEffect(numberPulse ? 1.22 : 1)
                .opacity(numberPulse ? 0.45 : 1)
                .id(value)
        }
        .frame(width: dialSize, height: dialSize)
    }

    /// 90° koyu sektör, her saniyede bir tam tur (conic / trim).
    @ViewBuilder
    private var sweep: some View {
        if reduceMotion {
            EmptyView()
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                let phase = context.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 1)
                Circle()
                    .fill(
                        AngularGradient(
                            stops: [
                                .init(color: ink.opacity(0.3), location: 0),
                                .init(color: ink.opacity(0.3), location: 0.25),
                                .init(color: .clear, location: 0.2501),
                                .init(color: .clear, location: 1),
                            ],
                            center: .center
                        )
                    )
                    .rotationEffect(.degrees(phase * 360))
            }
        }
    }

    // MARK: Zamanlama

    private func pulseNumber() async {
        guard !reduceMotion else {
            numberPulse = false
            return
        }
        numberPulse = true
        withAnimation(.easeOut(duration: 0.18)) { numberPulse = false }
    }

    /// §08 A1 "sonunda projektör titremesi". Son rakamın içinde ~180 ms.
    private func flickerIfLast() async {
        guard value == 1, !reduceMotion, FilmEffects.decorationsEnabled else {
            flicker = 0
            return
        }
        try? await Task.sleep(for: .milliseconds(620))
        for depth in [1.0, 0.7] {
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.04)) { flicker = depth }
            try? await Task.sleep(for: .milliseconds(45))
            withAnimation(.easeOut(duration: 0.05)) { flicker = 0 }
            try? await Task.sleep(for: .milliseconds(45))
        }
    }
}

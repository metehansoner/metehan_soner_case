import SwiftUI

/// Ekran 14 — 02-ekran-akisi.md §4, görseli 08-sinematik-detaylar.md A1.
///
/// Eski film makaralarının başındaki Akademi geri sayımı: iki eşmerkezli daire,
/// artı işareti, 1 saniyede tam tur atan süpürge kolu, ortada büyük rakam.
/// Üstünde eskimiş kopyanın çizik/toz katmanı, sonunda projektör titremesi.
///
/// §08 §0: **atlanamayan tek animasyon.** Bu 3 saniyede motion baseline'ı
/// alınıyor, kelime havuzu hazırlanıyor ve replay kaydı başlıyor.
/// Dokunmak kalan süreyi 1 saniyeye indiriyor, sıfırlamıyor.
struct CountdownView: View {
    let value: Int
    var onTap: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Son rakamda lambanın tutukluk yapması: 0 = normal, 1 = sönük.
    @State private var flicker: Double = 0

    var body: some View {
        ZStack {
            VelvetBackground()

            // A1: merkezden dışa açılan sıcak huzme.
            EllipticalGradient(
                colors: [AppColors.bgSpotlight.opacity(0.4), .clear],
                center: .center,
                startRadiusFraction: 0,
                endRadiusFraction: 0.7
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                leader
                Text(l10n.t("game.countdown.caption"))
                    .font(AppFont.display(14, weight: .semibold))
                    .appTracking(5)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.accentGold)
            }

            // A1: eskimiş kopyanın çizikleri. Rakamın üstünde ama huzmenin
            // içinde — makaranın kendisi çizik, projeksiyon değil.
            ScratchOverlay()

            // Projektör titremesi: ampul bir an düşüyor. Kararma değil sönme,
            // o yüzden siyah değil kırık beyaz.
            Color(hex: 0x120E0A)
                .opacity(flicker * 0.55)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value)")
        .task(id: value) { await flickerIfLast() }
    }

    /// §08 A1 "sonunda projektör titremesi". Son rakamda, tam oyun kartına
    /// geçmeden: iki hızlı düşüş, toplam ~180 ms. Süre eklemiyor — geri sayımın
    /// son saniyesinin içinde geçiyor.
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

    private var leader: some View {
        ZStack {
            sweep

            Circle()
                .strokeBorder(AppColors.accentGold.opacity(0.55), lineWidth: 3)

            // Artı işareti: dikey ve yatay tam çap.
            Rectangle()
                .fill(AppColors.accentGold.opacity(0.55))
                .frame(width: 1.5)
            Rectangle()
                .fill(AppColors.accentGold.opacity(0.55))
                .frame(height: 1.5)

            Text("\(value)")
                .font(AppFont.display(126, weight: .bold))
                .foregroundStyle(AppColors.surfacePoster)
                .shadow(color: AppColors.accentAmber.opacity(0.75), radius: 20)
                // Rakam değişimi tek kare kesme: rakamlar arası geçiş
                // animasyonu 1 saniyelik ritmi bulanıklaştırıyor.
                .id(value)
        }
        .frame(width: 196, height: 196)
    }

    /// Süpürge kolu: her rakamda bir tam tur. Reduce Motion açıkken dönmüyor
    /// ama daire kalıyor — geri sayım rakamı tek başına bilgiyi taşıyor.
    @ViewBuilder
    private var sweep: some View {
        if reduceMotion {
            EmptyView()
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 24)) { context in
                let phase = context.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 1)
                Circle()
                    .trim(from: 0, to: 0.25)
                    .fill(
                        AngularGradient(
                            colors: [AppColors.accentAmber.opacity(0.28), .clear],
                            center: .center
                        )
                    )
                    .rotationEffect(.degrees(phase * 360 - 90))
            }
        }
    }
}

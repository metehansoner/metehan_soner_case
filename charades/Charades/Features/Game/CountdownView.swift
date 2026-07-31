import SwiftUI

/// Ekran 14 — 02-ekran-akisi.md §4, görseli 08-sinematik-detaylar.md A1.
///
/// Eski film makaralarının başındaki Akademi geri sayımı: iki eşmerkezli daire,
/// artı işareti, 1 saniyede tam tur atan süpürge kolu, ortada büyük rakam.
/// A1'in "çizik/toz katmanı" ve projektör titremesi bezemeleri P17'de.
///
/// §08 §0: **atlanamayan tek animasyon.** Bu 3 saniyede motion baseline'ı
/// alınıyor, kelime havuzu hazırlanıyor ve (P15'te) replay kaydı başlıyor.
/// Dokunmak kalan süreyi 1 saniyeye indiriyor, sıfırlamıyor.
struct CountdownView: View {
    let value: Int
    var onTap: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    .tracking(5)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.accentGold)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value)")
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

import SwiftUI

/// Ekran 1 — 02-ekran-akisi.md §4, animasyonu 08-sinematik-detaylar.md A3.
///
/// Tek işi var: uygulama hazırlanırken geçen süreyi boş bir yükleme ekranı
/// yerine perde açılışına çevirmek. §08'in temel ilkesi burada da geçerli —
/// **var olan bir beklemeyi süslüyor, yeni bekleme yaratmıyor.**
///
/// Launch screen yalnızca kapalı perdeyi gösterir (`ornek-ekranlar.html` 1a).
/// İkon perdenin **arkasındadır**; perde iki yana çekilince sahne, spot ve
/// çerçeveli ikon belirir (1b).
struct CurtainRevealView: View {
    var onFinish: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isOpen = false
    @State private var showsStage = false

    /// Splash süresi — perde + sahne görünümü.
    private let total: TimeInterval = 2.0
    private let plaqueSide: CGFloat = 168

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Perdenin arkası — sahne, spot, ikon, wordmark.
                AppColors.screenBackground

                spotCone
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(showsStage ? 1 : 0)

                plaque
                    .opacity(showsStage ? 1 : 0)

                wordmark
                    .frame(maxHeight: .infinity, alignment: .center)
                    .offset(y: plaqueSide / 2 + 54)
                    .opacity(showsStage ? 1 : 0)

                // Kanatlar en üstte: kapalıyken sahneyi tamamen örter.
                panel(.leading, size: geometry.size)
                panel(.trailing, size: geometry.size)

                // 1b — `ornek-ekranlar.html` `.splash-load`: perde açılınca alt kenarda.
                loader
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 56)
                    .opacity(showsStage ? 1 : 0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        // §02 §4: splash'ta hiçbir dokunulabilir öğe yok, atlama butonu bile.
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(l10n.t("app.name"))
        .task { await run() }
    }

    // MARK: Katmanlar

    /// Sahne ışığı — `ornek-ekranlar.html` `.spotcone`. Perde açılınca üstten
    /// ikona düşen konik amber huzme; kapalıyken yok.
    private var spotCone: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width * 0.64, 280)
            let height = geometry.size.height * 0.52
            LinearGradient(
                colors: [
                    AppColors.accentAmber.opacity(0.30),
                    AppColors.bgSpotlight.opacity(0.14),
                    .clear,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: width, height: height)
            .clipShape(SpotConeShape())
            .blur(radius: 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .offset(y: -geometry.size.height * 0.06)
        }
        .allowsHitTesting(false)
    }

    /// Kadife kanat. Kenara giderken `scaleX` 0.6'ya düşüyor: gerçek sahne
    /// perdesi kenara toplanınca kalınlaşır, düz kaydırma bunu kaçırıyor (A3).
    private func panel(_ edge: HorizontalEdge, size: CGSize) -> some View {
        let isLeading = edge == .leading
        return Image("launch_curtain")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size.width, height: size.height)
            .clipped()
            .mask(alignment: isLeading ? .leading : .trailing) {
                Rectangle().frame(width: size.width / 2)
            }
            .scaleEffect(x: isOpen ? 0.6 : 1, anchor: isLeading ? .leading : .trailing)
            .offset(x: isOpen ? (isLeading ? -size.width * 0.62 : size.width * 0.62) : 0)
    }

    /// Çerçeveli app ikonu — perdenin arkasında; kanatlar açılınca görünür.
    private var plaque: some View {
        Image("launch_plaque")
            .frame(width: plaqueSide, height: plaqueSide)
            .overlay {
                BulbRing(countPerSide: 8, diameter: 4, color: AppColors.accentAmber, isLit: showsStage)
                    .padding(-11)
            }
            .shadow(color: AppColors.accentAmber.opacity(showsStage ? 0.55 : 0), radius: 36, y: 0)
            .shadow(color: .black.opacity(0.55), radius: 26, y: 14)
    }

    private var wordmark: some View {
        VStack(spacing: 9) {
            Text(l10n.t("app.name"))
                .font(AppFont.display(34, weight: .bold))
                .appTracking(6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textCream)
                .shadow(color: AppColors.accentAmber.opacity(showsStage ? 0.5 : 0), radius: 11)

            HStack(spacing: 8) {
                rule
                Text(l10n.t("app.tagline"))
                    .textStyle(.sectionLabel)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize()
                rule
            }
            .frame(maxWidth: 240)
        }
    }

    private var rule: some View {
        Rectangle()
            .fill(AppColors.accentGold.opacity(0.45))
            .frame(height: 1)
    }

    /// Alt kenar yükleme — kayan amber şerit + "Makara yükleniyor"
    /// (`ornek-ekranlar.html` `.load-track` / `.load-txt`).
    private var loader: some View {
        VStack(spacing: 10) {
            ReelLoadTrack()
            Text(l10n.t("launch.loading"))
                .font(AppFont.ui(8, weight: .semibold))
                .appTracking(2.6)
                .textCase(.uppercase)
                .foregroundStyle(Color(hex: 0x6F6152))
        }
    }

    // MARK: Akış

    private func run() async {
        SoundService.curtainOpen()

        guard !reduceMotion else {
            // §02 §4: Reduced Motion'da perde animasyonu yerine 200 ms fade.
            // Çerçeveli ikon yine görünüyor, ampuller sabit yanıyor.
            await prepareCatalog()
            withAnimation(.easeOut(duration: 0.2)) {
                isOpen = true
                showsStage = true
            }
            try? await Task.sleep(for: .milliseconds(200))
            onFinish()
            return
        }

        withAnimation(.easeInOut(duration: total * 0.85).delay(0.12)) {
            isOpen = true
            showsStage = true
        }

        async let prepared: Void = prepareCatalog()
        async let shown: Void = holdFullDuration()
        _ = await (prepared, shown)
        onFinish()
    }

    /// §02 §4: hazırlık 1,2 saniyeden kısa sürdüyse **yine de** bekleniyor.
    /// Yarım kesilmiş animasyon hızlı açılıştan kötü hissettiriyor.
    private func holdFullDuration() async {
        try? await Task.sleep(for: .seconds(total))
    }

    /// Deste kataloğu ilk erişimde kuruluyor (§05 §2). Kelime dosyaları
    /// okunmuyor — onlar deste seçilince geliyor (§05 §5).
    private func prepareCatalog() async {
        await Task { @MainActor in _ = DeckCatalog.v1 }.value
    }
}

/// 104×2 pt ray, içinde %42 amber dilim soldan sağa kayıyor (1,4 sn döngü).
private struct ReelLoadTrack: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var travel: CGFloat = 0

    private let trackWidth: CGFloat = 104
    private let segmentRatio: CGFloat = 0.42

    var body: some View {
        let segment = trackWidth * segmentRatio
        Capsule()
            .fill(AppColors.accentGold.opacity(0.22))
            .frame(width: trackWidth, height: 2)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(AppColors.accentAmber)
                    .frame(width: segment, height: 2)
                    .shadow(color: AppColors.accentAmber.opacity(0.8), radius: 4)
                    .offset(x: reduceMotion ? (trackWidth - segment) / 2 : travel)
            }
            .clipped()
            .onAppear {
                guard !reduceMotion else { return }
                travel = -segment * 1.1
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) {
                    travel = trackWidth + segment * 0.4
                }
            }
    }
}

/// Üstte dar, altta geniş — sahne spotunun trapez kesiti
/// (`clip-path: polygon(38% 0, 62% 0, 100% 100%, 0 100%)`).
private struct SpotConeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topInset = rect.width * 0.38
        path.move(to: CGPoint(x: topInset, y: 0))
        path.addLine(to: CGPoint(x: rect.width - topInset, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

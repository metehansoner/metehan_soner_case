import SwiftUI

/// Ekran 1 — 02-ekran-akisi.md §4, animasyonu 08-sinematik-detaylar.md A3.
///
/// Tek işi var: uygulama hazırlanırken geçen süreyi boş bir yükleme ekranı
/// yerine perde açılışına çevirmek. §08'in temel ilkesi burada da geçerli —
/// **var olan bir beklemeyi süslüyor, yeni bekleme yaratmıyor.**
///
/// Perde ve levha, statik launch screen'in gösterdiği **aynı iki PNG**
/// (`LaunchScreen.storyboard`). Aynı kareyi iki kez çizmek yerine tek dosyayı
/// paylaşmak, sistem açılış ekranından bu view'a geçerken hiçbir şeyin yerinden
/// zıplamamasını garanti ediyor.
struct CurtainRevealView: View {
    var onFinish: () -> Void

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isOpen = false
    @State private var showsStage = false
    @State private var showsLoader = false

    /// §08 A3: toplam 1,2 saniye.
    private let total: TimeInterval = 1.2
    private let plaqueSide: CGFloat = 168

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Perdenin arkası: ışığın vurduğu sahne.
                AppColors.screenBackground
                EllipticalGradient(
                    colors: [AppColors.bgSpotlight.opacity(0.32), .clear],
                    center: .center,
                    startRadiusFraction: 0,
                    endRadiusFraction: 0.75
                )

                wordmark
                    .frame(maxHeight: .infinity, alignment: .center)
                    .offset(y: plaqueSide / 2 + 54)
                    .opacity(showsStage ? 1 : 0)

                panel(.leading, size: geometry.size)
                panel(.trailing, size: geometry.size)

                plaque

                if showsLoader {
                    loader
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 54)
                        .transition(.opacity)
                }
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

    /// Çerçeveli app ikonu. Perdenin **üstünde** duruyor: launch screen'de de
    /// öyle görünüyor ve açılış boyunca yerinden kımıldamayan tek öğe o.
    private var plaque: some View {
        Image("launch_plaque")
            .frame(width: plaqueSide, height: plaqueSide)
            .overlay {
                // Ana ekrandaki logo ampulleriyle aynı ritim; iki ekran
                // arasında kesinti değil süreklilik oluyor (§02 §4).
                BulbFrame(countPerEdge: 6, diameter: 4, color: AppColors.accentAmber)
                    .padding(-9)
            }
            .shadow(color: .black.opacity(0.55), radius: 26, y: 14)
    }

    private var wordmark: some View {
        VStack(spacing: 9) {
            Text(l10n.t("app.name"))
                .font(AppFont.display(34, weight: .bold))
                .appTracking(6)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textCream)

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

    /// §02 §4 madde 5: **normal açılışta hiç görünmüyor.** Yalnızca katalog
    /// hazırlığı perde animasyonundan uzun sürerse.
    private var loader: some View {
        VStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppColors.accentAmber)
            Text(l10n.t("launch.loading"))
                .font(AppFont.ui(9.5, weight: .semibold))
                .appTracking(2.4)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: Akış

    private func run() async {
        SoundService.curtainOpen()

        guard !reduceMotion else {
            // §02 §4: Reduced Motion'da perde animasyonu yerine 200 ms fade.
            // Çerçeveli ikon yine görünüyor, ampuller sabit yanıyor.
            await prepareCatalog()
            withAnimation(.easeOut(duration: 0.2)) { showsStage = true }
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
        let loader = Task { @MainActor in _ = DeckCatalog.v1 }

        // Gösterge hazırlık uzarsa devreye giriyor; normal açılışta bu bekleme
        // hazırlıktan önce bitiyor ve gösterge hiç çizilmiyor.
        let watchdog = Task { @MainActor in
            try? await Task.sleep(for: .seconds(total))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.2)) { showsLoader = true }
        }

        await loader.value
        watchdog.cancel()
    }
}

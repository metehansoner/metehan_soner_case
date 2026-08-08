import SwiftUI

/// Oyun / replay içeriğini **pencere portrait kalsın** diye 90° döndürür.
///
/// `requestGeometryUpdate(.landscape)` cihaz yön kilidi açıksa reddediliyor;
/// bu kapsayıcı sistem yönüne hiç bağlanmadan landscape düzeni (genişlik >
/// yükseklik) sunuyor. Telefon fiziksel olarak yatay tutulunca (alna koyunca)
/// içerik doğru tarafta okunuyor — Control Center kilidi fark etmiyor.
///
/// iPad / geniş pencerede sahne telefon boyutuna tavanlanır; aksi hâlde
/// 90° dönüş sonrası kontroller ekran dışına kaçar.
struct ForcedLandscapeContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GeometryReader { geometry in
            let portrait = geometry.size
            let canvas = Self.canvasSize(
                fitting: portrait,
                regular: AppLayout.isRegularWidth(horizontalSizeClass)
            )

            content()
                .frame(width: canvas.width, height: canvas.height)
                // landscapeRight: home tuşu sağda — alna koyma alışkanlığı.
                .rotationEffect(.degrees(-90))
                .frame(width: portrait.width, height: portrait.height)
        }
        .ignoresSafeArea()
    }

    /// Portrait pencereye sığacak landscape sahne. Regular’da iPhone landscape
    /// ölçüsüne yakın tavan; compact’ta klasik tam dönüş.
    private static func canvasSize(fitting portrait: CGSize, regular: Bool) -> CGSize {
        var width = portrait.height
        var height = portrait.width
        guard regular else { return CGSize(width: width, height: height) }

        width = min(width, AppLayout.landscapeStageMaxWidth)
        height = min(height, AppLayout.landscapeStageMaxHeight)
        // Oranı koru: tavanlardan biri baskınsa diğerini de ölçekle.
        let aspect = AppLayout.landscapeStageMaxWidth / AppLayout.landscapeStageMaxHeight
        if width / height > aspect {
            width = height * aspect
        } else {
            height = width / aspect
        }
        return CGSize(width: width, height: height)
    }
}

extension View {
    /// `enabled` iken içeriği forced-landscape kapsayıcıya alır.
    @ViewBuilder
    func forcedLandscape(_ enabled: Bool = true) -> some View {
        if enabled {
            ForcedLandscapeContainer { self }
        } else {
            self
        }
    }
}

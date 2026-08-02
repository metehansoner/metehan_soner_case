import SwiftUI

/// Oyun / replay içeriğini **pencere portrait kalsın** diye 90° döndürür.
///
/// `requestGeometryUpdate(.landscape)` cihaz yön kilidi açıksa reddediliyor;
/// bu kapsayıcı sistem yönüne hiç bağlanmadan landscape düzeni (genişlik >
/// yükseklik) sunuyor. Telefon fiziksel olarak yatay tutulunca (alna koyunca)
/// içerik doğru tarafta okunuyor — Control Center kilidi fark etmiyor.
struct ForcedLandscapeContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            let portrait = geometry.size
            // Yerel koordinat: landscape (uzun kenar yatay).
            let landscape = CGSize(width: portrait.height, height: portrait.width)

            content()
                .frame(width: landscape.width, height: landscape.height)
                // landscapeRight: home tuşu sağda — alna koyma alışkanlığı.
                .rotationEffect(.degrees(-90))
                .frame(width: portrait.width, height: portrait.height)
        }
        .ignoresSafeArea()
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

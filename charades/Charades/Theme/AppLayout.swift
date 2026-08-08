import SwiftUI

/// iPhone düzenini iPad / geniş pencerede okunabilir tutan ölçüler.
///
/// Native iPad’de içerik telefon genişliğinde ortalanıyor; sabit “telefon
/// yüksekliği” varsayımları (paywall duvarı, forced-landscape) kısa kenarda
/// taşmasın diye tavanlanıyor.
enum AppLayout {
    /// Ana kolon / paywall / sheet gövdesi.
    static let readableWidth: CGFloat = 500
    /// Izgara ve kart şeritleri biraz daha geniş olabilir.
    static let gridWidth: CGFloat = 720
    /// Forced-landscape oyun sahnesi (yatay düzen) tavanı — iPad’de devasa
    /// sahne üretmesin.
    static let landscapeStageMaxWidth: CGFloat = 844
    static let landscapeStageMaxHeight: CGFloat = 430

    static func isRegularWidth(_ sizeClass: UserInterfaceSizeClass?) -> Bool {
        sizeClass == .regular
    }
}

extension View {
    /// Geniş ekranda içeriği ortalar ve `maxWidth` ile sınırlar.
    func readableWidth(_ maxWidth: CGFloat = AppLayout.readableWidth) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

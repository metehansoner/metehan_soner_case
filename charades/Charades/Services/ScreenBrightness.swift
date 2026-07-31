import UIKit

/// § `04` §1 `Canlandır`: telefonu **canlandıran** tutuyor, karşısındakiler
/// tahmin ediyor. Ekran içeriğinin tahmin edenlere sızmaması için kelime küçük
/// ve tek satır, ekran parlaklığı da düşürülüyor.
///
/// Parlaklık sistem genelinde bir değer: değiştiren onu geri vermek zorunda.
/// Bu yüzden tek giriş noktası burası ve `restore()` her faz geçişinde,
/// duraklatmada ve turdan çıkışta çağrılıyor — uygulama arka plana atılırsa
/// kullanıcı parlaklığı kısılmış bir telefonla kalmasın.
@MainActor
enum ScreenBrightness {
    /// Kelime hâlâ okunuyor ama bir metre öteden seçilmiyor.
    private static let dimLevel: CGFloat = 0.25

    private static var savedLevel: CGFloat?

    static func dim() {
        guard savedLevel == nil else { return }
        let current = UIScreen.main.brightness
        // Kullanıcı zaten daha kısıkta oynuyorsa artırmıyoruz.
        guard current > dimLevel else { return }
        savedLevel = current
        UIScreen.main.brightness = dimLevel
    }

    static func restore() {
        guard let savedLevel else { return }
        UIScreen.main.brightness = savedLevel
        self.savedLevel = nil
    }
}

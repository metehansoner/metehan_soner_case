import SwiftUI
import UIKit

enum Keyboard {
    static func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

extension View {
    /// Görünen boyutu değiştirmeden dokunma alanını en az 44pt'ye açar.
    ///
    /// 01-tasarim-sistemi.md'nin "modern retro" tablosu tipografiyi ve dokunma
    /// hedeflerini bilinçli olarak modern tarafta bırakıyor: kapatma çarpısı 26pt
    /// bir daire olarak **görünebilir** ama 26pt bir hedef olarak ıskalanıyor.
    /// Rozetin kendisini büyütmek yerine yalnızca vurulabilir alan büyüyor.
    func tapTarget(_ side: CGFloat = 44) -> some View {
        frame(minWidth: side, minHeight: side)
            .contentShape(Rectangle())
    }

    /// Boş zemine dokununca klavyeyi kapatır.
    ///
    /// `simultaneousGesture` kullanılmıyor: `+` / Kaydet ile aynı anda
    /// `resignFirstResponder` olursa odak geri gelince ScrollView giriş
    /// alanına zıplıyor.
    func dismissKeyboardOnTap() -> some View {
        background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: Keyboard.dismiss)
        }
    }
}

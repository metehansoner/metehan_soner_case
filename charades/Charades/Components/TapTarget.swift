import SwiftUI

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
}

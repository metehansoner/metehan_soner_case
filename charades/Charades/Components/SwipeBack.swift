import SwiftUI

/// `Imposter/Components/SwipeBack.swift`'ten taşındı (§07 §9).
///
/// Ekranlar `navigationBarHidden(true)` kullandığı için native swipe-back
/// kayboluyor; sol kenardan başlayan yatay sürükleme onun yerine geçiyor (§02 §5).
extension View {
    func onSwipeBack(perform action: @escaping () -> Void) -> some View {
        modifier(SwipeBackModifier(action: action))
    }
}

private struct SwipeBackModifier: ViewModifier {
    let action: () -> Void

    /// §06 §2: Arapça'da geri hareketi ekranın sağ kenarından sola doğru.
    @Environment(\.layoutDirection) private var layoutDirection

    /// Sağ kenarın nerede olduğu ekran genişliğinden okunuyor; `GeometryReader`
    /// içeriği sarmalayamaz (açgözlü yerleşimi ekranları bozar), o yüzden
    /// arka planda ölçülüyor.
    @State private var trailingEdge: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geometry in
                    let maxX = geometry.frame(in: .global).maxX
                    Color.clear
                        .onAppear { trailingEdge = maxX }
                        .onChange(of: maxX) { _, new in trailingEdge = new }
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 24, coordinateSpace: .global)
                    .onEnded { value in
                        guard abs(value.translation.height) < 80 else { return }
                        if layoutDirection == .rightToLeft {
                            guard value.startLocation.x >= trailingEdge - 44,
                                  value.translation.width < -70 else { return }
                        } else {
                            guard value.startLocation.x <= 44,
                                  value.translation.width > 70 else { return }
                        }
                        action()
                    }
            )
    }
}

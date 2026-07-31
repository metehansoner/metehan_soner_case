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

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 24, coordinateSpace: .global)
                .onEnded { value in
                    guard value.startLocation.x <= 44 else { return }
                    guard value.translation.width > 70, abs(value.translation.height) < 80 else { return }
                    action()
                }
        )
    }
}

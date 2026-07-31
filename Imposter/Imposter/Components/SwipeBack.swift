import SwiftUI

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
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard value.startLocation.x <= 44 else { return }
                    guard dx > 70, abs(dy) < 80 else { return }
                    Haptics.light()
                    action()
                }
        )
    }
}

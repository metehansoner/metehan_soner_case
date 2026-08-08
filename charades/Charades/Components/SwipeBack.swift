import SwiftUI


extension View {
    func onSwipeBack(perform action: @escaping () -> Void) -> some View {
        modifier(SwipeBackModifier(action: action))
    }
}

private struct SwipeBackModifier: ViewModifier {
    let action: () -> Void


    @Environment(\.layoutDirection) private var layoutDirection


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

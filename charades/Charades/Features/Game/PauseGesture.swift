import SwiftUI
import UIKit


struct PauseGesture: ViewModifier {
    var allowsTwoFingerTap: Bool

    var onGestureBegan: () -> Void
    var onPause: () -> Void

    @State private var didLockThisDrag = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if allowsTwoFingerTap {
                    TwoFingerTapCatcher(action: onPause)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .local)
                    .onChanged { value in


                        guard value.startLocation.y < 70 else { return }
                        if !didLockThisDrag {
                            didLockThisDrag = true
                            onGestureBegan()
                        }
                    }
                    .onEnded { value in
                        defer { didLockThisDrag = false }
                        guard value.startLocation.y < 70,
                              value.translation.height > 90
                        else { return }
                        onPause()
                    }
            )
    }
}

extension View {
    func pauseGesture(
        allowsTwoFingerTap: Bool,
        onGestureBegan: @escaping () -> Void,
        onPause: @escaping () -> Void
    ) -> some View {
        modifier(
            PauseGesture(
                allowsTwoFingerTap: allowsTwoFingerTap,
                onGestureBegan: onGestureBegan,
                onPause: onPause
            )
        )
    }
}


private struct TwoFingerTapCatcher: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = PassthroughView()
        view.onAttach = { window in
            let recognizer = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.fire)
            )
            recognizer.numberOfTouchesRequired = 2
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = context.coordinator
            window.addGestureRecognizer(recognizer)
            return recognizer
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var action: () -> Void

        init(action: @escaping () -> Void) { self.action = action }

        @objc func fire() { action() }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool { true }
    }

    private final class PassthroughView: UIView {
        var onAttach: ((UIWindow) -> UIGestureRecognizer)?
        private weak var attached: UIGestureRecognizer?

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let attached {
                attached.view?.removeGestureRecognizer(attached)
                self.attached = nil
            }
            if let window { attached = onAttach?(window) }
        }
    }
}

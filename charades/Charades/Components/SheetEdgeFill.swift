import SwiftUI
import UIKit

/// Fraction detent sheet'lerde SwiftUI bazen container'ı şeffaf bırakıyor;
/// UIKit tarafında opak zemin + alt kenara yapışma zorlanıyor.
struct SheetEdgeFill: UIViewRepresentable {
    var color: UIColor

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let paint = color
        DispatchQueue.main.async {
            guard let host = uiView.nearestViewController() else { return }
            if let sheet = host.sheetPresentationController {
                sheet.prefersEdgeAttachedInCompactHeight = true
                sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            }
            host.view.backgroundColor = paint
            var node: UIView? = host.view.superview
            var depth = 0
            while let view = node, depth < 6 {
                let name = String(describing: type(of: view))
                if name.contains("Sheet")
                    || name.contains("DropShadow")
                    || name.contains("Presentation")
                    || name.contains("Hosting") {
                    view.backgroundColor = paint
                }
                node = view.superview
                depth += 1
            }
        }
    }
}

private extension UIView {
    func nearestViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let controller = current as? UIViewController {
                return controller
            }
            responder = current.next
        }
        return nil
    }
}

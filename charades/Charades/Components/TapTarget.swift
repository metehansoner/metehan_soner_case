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


    func tapTarget(_ side: CGFloat = 44) -> some View {
        frame(minWidth: side, minHeight: side)
            .contentShape(Rectangle())
    }


    func dismissKeyboardOnTap() -> some View {
        background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: Keyboard.dismiss)
        }
    }
}

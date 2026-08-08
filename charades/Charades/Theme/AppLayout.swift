import SwiftUI


enum AppLayout {

    static let readableWidth: CGFloat = 500

    static let gridWidth: CGFloat = 720


    static let landscapeStageMaxWidth: CGFloat = 844
    static let landscapeStageMaxHeight: CGFloat = 430

    static func isRegularWidth(_ sizeClass: UserInterfaceSizeClass?) -> Bool {
        sizeClass == .regular
    }
}

extension View {

    func readableWidth(_ maxWidth: CGFloat = AppLayout.readableWidth) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

import SwiftUI


struct ForcedLandscapeContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GeometryReader { geometry in
            let portrait = geometry.size
            let canvas = Self.canvasSize(
                fitting: portrait,
                regular: AppLayout.isRegularWidth(horizontalSizeClass)
            )

            content()
                .frame(width: canvas.width, height: canvas.height)

                .rotationEffect(.degrees(-90))
                .frame(width: portrait.width, height: portrait.height)
        }
        .ignoresSafeArea()
    }


    private static func canvasSize(fitting portrait: CGSize, regular: Bool) -> CGSize {
        var width = portrait.height
        var height = portrait.width
        guard regular else { return CGSize(width: width, height: height) }

        width = min(width, AppLayout.landscapeStageMaxWidth)
        height = min(height, AppLayout.landscapeStageMaxHeight)

        let aspect = AppLayout.landscapeStageMaxWidth / AppLayout.landscapeStageMaxHeight
        if width / height > aspect {
            width = height * aspect
        } else {
            height = width / aspect
        }
        return CGSize(width: width, height: height)
    }
}

extension View {

    @ViewBuilder
    func forcedLandscape(_ enabled: Bool = true) -> some View {
        if enabled {
            ForcedLandscapeContainer { self }
        } else {
            self
        }
    }
}

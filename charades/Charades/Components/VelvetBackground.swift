import SwiftUI


struct VelvetBackground: View {

    var showsCurtain = false

    var showsLightLeak = false
    var showsGrain = true

    var body: some View {
        ZStack {
            AppColors.screenBackground

            if showsCurtain {
                CurtainDrape()
            }

            AppColors.spotlightOverlay

            if showsLightLeak {
                lightLeak
            }

            AppColors.vignette

            if showsGrain {
                GrainOverlay()
            }
        }
        .ignoresSafeArea()
    }

    private var lightLeak: some View {
        EllipticalGradient(
            colors: [AppColors.bgSpotlight.opacity(0.12), .clear],
            center: UnitPoint(x: 1, y: 0),
            startRadiusFraction: 0,
            endRadiusFraction: 0.55
        )
    }
}


private struct CurtainDrape: View {
    private let foldWidth: CGFloat = 26

    var body: some View {
        Canvas { context, size in
            let count = max(1, Int((size.width / foldWidth).rounded(.up)))
            for index in 0..<count {
                let x = CGFloat(index) * foldWidth
                let fold = CGRect(x: x, y: 0, width: foldWidth, height: size.height)
                context.fill(
                    Path(fold),
                    with: .linearGradient(
                        Gradient(colors: [
                            AppColors.bgVelvetDeep,
                            AppColors.bgVelvetMid,
                            AppColors.bgVelvetLight,
                            AppColors.bgVelvetMid,
                            AppColors.bgVelvetDeep,
                        ]),
                        startPoint: CGPoint(x: x, y: 0),
                        endPoint: CGPoint(x: x + foldWidth, y: 0)
                    )
                )
            }
        }
        .opacity(0.85)
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [AppColors.bgVelvetLight.opacity(0.55), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 90)
        }
    }
}

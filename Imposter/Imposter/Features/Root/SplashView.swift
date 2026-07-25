import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image("splash_icon")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 132, height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.85), lineWidth: 2.5)
                )
                .shadow(color: .white.opacity(0.12), radius: 18, y: 0)
        }
        .preferredColorScheme(.dark)
    }
}

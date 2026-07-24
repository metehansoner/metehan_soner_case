import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0
    private var l10n: LocalizationManager { .shared }

    private var pages: [(title: String, body: String, cta: String, image: String?)] {
        [
            (l10n.t("onboarding.1.title"), l10n.t("onboarding.1.body"), l10n.t("onboarding.1.cta"), "onboarding_01"),
            (l10n.t("onboarding.2.title"), l10n.t("onboarding.2.body"), l10n.t("onboarding.2.cta"), "onboarding_02"),
            (l10n.t("onboarding.3.title"), l10n.t("onboarding.3.body"), l10n.t("onboarding.3.cta"), "onboarding_03")
        ]
    }

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPage(
                            title: pages[index].title,
                            bodyText: pages[index].body,
                            assetName: pages[index].image
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    Haptics.light()
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(pages[page].cta)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }
}

private struct OnboardingPage: View {
    let title: String
    let bodyText: String
    let assetName: String?

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 24)

            Group {
                if let assetName, UIImage(named: assetName) != nil {
                    Image(assetName)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                } else {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AppColors.surfaceCard)
                        .overlay(
                            Image(systemName: "theatermasks.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(AppColors.accentCyan)
                        )
                }
            }
            .frame(maxHeight: 280)
            .padding(.horizontal, 28)

            Text(title)
                .font(AppFont.display(30, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text(bodyText)
                .font(AppFont.ui(16))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer(minLength: 80)
        }
    }
}

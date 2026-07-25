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
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageDots
                    .padding(.top, 4)
                    .padding(.bottom, 14)

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

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == page ? Color.white : Color.white.opacity(0.35))
                    .frame(width: index == page ? 18 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: page)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(page + 1) / \(pages.count)")
    }
}

private struct OnboardingPage: View {
    let title: String
    let bodyText: String
    let assetName: String?

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer(minLength: 8)

                VStack(spacing: 16) {
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
                                        .font(.system(size: 72))
                                        .foregroundStyle(AppColors.accentCyan)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: geo.size.height * 0.58)
                    .padding(.horizontal, 16)

                    VStack(spacing: 8) {
                        Text(title)
                            .font(AppFont.display(28, weight: .black))
                            .foregroundStyle(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(bodyText)
                            .font(AppFont.ui(15, weight: .bold))
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: 8)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

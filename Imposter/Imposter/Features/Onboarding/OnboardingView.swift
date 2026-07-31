import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0
    @State private var appear = false
    private var l10n: LocalizationManager { .shared }

    private var pages: [(eyebrow: String, title: String, body: String, cta: String, image: String?, symbol: String)] {
        [
            (
                l10n.t("onboarding.1.eyebrow"),
                l10n.t("onboarding.1.title"),
                l10n.t("onboarding.1.body"),
                l10n.t("onboarding.1.cta"),
                "onboarding_01",
                "person.3.fill"
            ),
            (
                l10n.t("onboarding.2.eyebrow"),
                l10n.t("onboarding.2.title"),
                l10n.t("onboarding.2.body"),
                l10n.t("onboarding.2.cta"),
                "onboarding_02",
                "hand.tap.fill"
            ),
            (
                l10n.t("onboarding.3.eyebrow"),
                l10n.t("onboarding.3.title"),
                l10n.t("onboarding.3.body"),
                l10n.t("onboarding.3.cta"),
                "onboarding_03",
                "theatermasks.fill"
            )
        ]
    }

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingStage(
                            eyebrow: pages[index].eyebrow,
                            title: pages[index].title,
                            bodyText: pages[index].body,
                            assetName: pages[index].image,
                            fallbackSymbol: pages[index].symbol,
                            step: index + 1
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: page)

                stepRail
                    .padding(.top, 6)
                    .padding(.bottom, 16)

                Button {
                    Haptics.medium()
                    if page < pages.count - 1 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { page += 1 }
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) { appear = true }
        }
    }

    private var topBar: some View {
        HStack {
            Text(l10n.t("app.name"))
                .font(AppFont.display(16, weight: .black))
                .foregroundStyle(AppColors.accentCyan)

            Spacer()

            if page < pages.count - 1 {
                Button {
                    Haptics.light()
                    onFinish()
                } label: {
                    Text(l10n.t("common.skip"))
                        .font(AppFont.ui(14, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(AppColors.surfaceCard.opacity(0.85)))
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(appear ? 1 : 0)
    }

    private var stepRail: some View {
        HStack(spacing: 10) {
            ForEach(pages.indices, id: \.self) { index in
                let active = index == page
                let done = index < page
                Capsule()
                    .fill(
                        active ? AppColors.accentYellow
                            : done ? AppColors.accentCyan.opacity(0.85)
                            : Color.white.opacity(0.28)
                    )
                    .frame(width: active ? 28 : 10, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: page)
                    .contentShape(Rectangle().size(CGSize(width: 28, height: 24)))
                    .onTapGesture {
                        guard index != page else { return }
                        Haptics.selection()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            page = index
                        }
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(page + 1) / \(pages.count)")
    }
}

private struct OnboardingStage: View {
    let eyebrow: String
    let title: String
    let bodyText: String
    let assetName: String?
    let fallbackSymbol: String
    let step: Int

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer(minLength: 6)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppColors.accentCyan.opacity(0.35), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 180
                            )
                        )
                        .frame(width: 300, height: 300)

                    Group {
                        if let assetName, UIImage(named: assetName) != nil {
                            Image(assetName)
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                        } else {
                            Image(systemName: fallbackSymbol)
                                .font(.system(size: 84, weight: .bold))
                                .foregroundStyle(AppColors.accentCyan)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                                        .fill(AppColors.surfaceCard)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: geo.size.height * 0.46)
                    .padding(.horizontal, 20)
                }

                VStack(spacing: 10) {
                    Text(eyebrow)
                        .font(AppFont.section(13))
                        .foregroundStyle(AppColors.accentYellow)
                        .textCase(.uppercase)

                    Text(title)
                        .font(AppFont.display(30, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(bodyText)
                        .font(AppFont.ui(16, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)
                .padding(.top, 8)

                Spacer(minLength: 8)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

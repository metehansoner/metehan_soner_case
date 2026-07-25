import SwiftUI

struct HomeView: View {
    @Bindable var session: GameSession
    var showsCloseButton: Bool = true
    var showsProfileButton: Bool = false
    var onProfile: (() -> Void)? = nil
    var onModeSelected: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Bindable private var l10n = LocalizationManager.shared

    @State private var showSettings = false
    @State private var showInfo = false

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 20) {
                header

                modeCard(
                    title: l10n.t("home.classicTitle"),
                    subtitle: l10n.t("home.classicSubtitle"),
                    mode: .classic,
                    imageName: "mode_classic",
                    useGradient: false
                )

                modeCard(
                    title: l10n.t("home.drawingTitle"),
                    subtitle: l10n.t("home.drawingSubtitle"),
                    mode: .drawing,
                    imageName: "mode_drawing",
                    useGradient: true
                )

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        .sheet(isPresented: $showInfo) {
            HowToPlaySheet()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if showsCloseButton {
                HeaderCircleIconButton(systemName: "xmark") {
                    Haptics.light()
                    dismiss()
                }
            } else if showsProfileButton {
                HeaderCircleIconButton(systemName: "person.fill") {
                    onProfile?()
                }
            }

            Image("home_logo")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .accessibilityLabel(l10n.t("app.name"))

            HeaderCircleIconButton(systemName: "gearshape.fill") {
                Haptics.light()
                showSettings = true
            }

            HeaderCircleIconButton(systemName: "info.circle.fill") {
                Haptics.light()
                showInfo = true
            }
        }
    }

    private func modeCard(
        title: String,
        subtitle: String,
        mode: GameMode,
        imageName: String,
        useGradient: Bool
    ) -> some View {
        let selected = session.selectedMode == mode
        let border = selected
            ? AppColors.accentCyan
            : AppColors.accentCyan.opacity(useGradient ? 0.55 : 0.4)
        let glow = selected
            ? AppColors.accentCyan.opacity(0.55)
            : AppColors.accentCyan.opacity(useGradient ? 0.35 : 0.28)

        return Button {
            Haptics.medium()
            session.selectedMode = mode
            AppSettingsStore.shared.lastGameMode = mode
            onModeSelected?()
            if showsCloseButton {
                dismiss()
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(AppFont.display(26, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)

                    Text(subtitle)
                        .font(AppFont.ui(15, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.95))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Image(imageName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 118, height: 118)
                    .shadow(color: AppColors.accentCyan.opacity(0.55), radius: 16, y: 4)
            }
            .padding(.leading, 20)
            .padding(.trailing, 12)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: 156, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(useGradient ? AnyShapeStyle(AppColors.drawCardGradient) : AnyShapeStyle(AppColors.surfaceCard))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(border, lineWidth: selected ? 2.5 : 1.5)
                    )
                    .shadow(color: glow, radius: selected ? 18 : 14, y: 0)
                    .shadow(color: .black.opacity(0.28), radius: 14, y: 8)
            }
        }
        .buttonStyle(.plain)
    }
}

struct HowToPlaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var l10n = LocalizationManager.shared
    @State private var page = 0

    private var pages: [(image: String, title: String, body: String, extra: String?)] {
        [
            ("tutorial_01_themes", l10n.t("tutorial.1.title"), l10n.t("tutorial.1.body"), nil),
            ("tutorial_02_role", l10n.t("tutorial.2.title"), l10n.t("tutorial.2.body"), nil),
            ("tutorial_03_hint", l10n.t("tutorial.3.title"), l10n.t("tutorial.3.body"), nil),
            (
                "tutorial_04_vote",
                l10n.t("tutorial.4.title"),
                l10n.t("tutorial.4.body"),
                l10n.t("tutorial.4.warning")
            )
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppColors.textSecondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 12)

            Text(l10n.t("round.howToTitle"))
                .font(AppFont.display(26, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.bottom, 8)

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    tutorialPage(pages[index], index: index)
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
                    dismiss()
                }
            } label: {
                Text(page < pages.count - 1 ? l10n.t("common.next") : l10n.t("common.gotIt"))
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OceanBackground())
        .presentationDetents([.large])
        .presentationCornerRadius(32)
        .onAppear { Haptics.light() }
    }

    private func tutorialPage(
        _ page: (image: String, title: String, body: String, extra: String?),
        index: Int
    ) -> some View {
        VStack(spacing: 16) {
            Spacer(minLength: 4)

            Image(page.image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 240)
                .padding(.horizontal, 12)

            Text("\(index + 1)/4")
                .font(AppFont.ui(13, weight: .bold))
                .foregroundStyle(AppColors.accentYellow)

            Text(page.title)
                .font(AppFont.display(28, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(page.body)
                .font(AppFont.ui(16, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            if let extra = page.extra {
                Text(extra)
                    .font(AppFont.ui(13, weight: .bold))
                    .foregroundStyle(AppColors.accentYellow)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppColors.surfaceCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(AppColors.accentYellow.opacity(0.35), lineWidth: 1)
                            )
                    )
                    .padding(.top, 4)
            }

            if index == 3 {
                HStack(spacing: 10) {
                    outcomeChip(l10n.t("tutorial.4.win"), color: AppColors.stateSuccess)
                    outcomeChip(l10n.t("tutorial.4.lose"), color: AppColors.stateDanger)
                }
                .padding(.top, 4)
            }

            Spacer(minLength: 4)
        }
        .padding(.horizontal, 24)
    }

    private func outcomeChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppFont.ui(12, weight: .bold))
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColors.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(color.opacity(0.7), lineWidth: 1.5)
                    )
            )
    }
}

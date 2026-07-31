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

    private var playerCount: Int { session.namedPlayers.count }

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 16) {
                header

                lobbyChip

                HStack {
                    Text(l10n.t("home.chooseMode"))
                        .font(AppFont.display(20, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                }
                .padding(.top, 2)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(GameMode.hubOrder) { mode in
                            modeCard(mode)
                        }
                    }
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
                .homeScrollEdgeFix()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .bottomBar)
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
    }

    private var lobbyChip: some View {
        Button {
            Haptics.light()
            onProfile?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.accentCyan)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppColors.surfaceCardElevated))

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.t("home.lobbyLabel"))
                        .font(AppFont.ui(12, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .textCase(.uppercase)
                    Text(l10n.t("home.playersReady", ["n": "\(playerCount)"]))
                        .font(AppFont.display(17, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                }

                Spacer()

                Text(l10n.t("home.editRoster"))
                    .font(AppFont.ui(14, weight: .bold))
                    .foregroundStyle(AppColors.btnPrimaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(AppColors.btnPrimaryBg))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppColors.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(AppColors.accentCyan.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        ZStack {
            Image("home_logo")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(height: 36)
                .frame(maxWidth: 220)
                .accessibilityLabel(l10n.t("app.name"))

            HStack(spacing: 0) {
                if showsCloseButton {
                    HeaderCircleIconButton(systemName: "xmark") {
                        Haptics.light()
                        dismiss()
                    }
                } else if showsProfileButton {
                    HeaderCircleIconButton(systemName: "person.fill") {
                        onProfile?()
                    }
                } else {
                    Color.clear.frame(width: 42, height: 42)
                }

                Spacer(minLength: 0)

                HeaderCircleIconButton(systemName: "gearshape.fill") {
                    Haptics.light()
                    showSettings = true
                }
            }
        }
        .frame(height: 44)
    }

    private func modeCard(_ mode: GameMode) -> some View {
        let gradient = mode.usesGradientCard
        let iconTint = gradient ? Color.white : AppColors.accentCyan

        return Button {
            Haptics.medium()
            session.selectedMode = mode
            AppSettingsStore.shared.lastGameMode = mode
            onModeSelected?()
            if showsCloseButton {
                dismiss()
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppColors.accentCyan.opacity(gradient ? 0.35 : 0.22),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 2,
                                endRadius: 36
                            )
                        )
                        .frame(width: 68, height: 68)

                    Image(mode.iconImageName)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 58, height: 58)
                        .shadow(color: AppColors.accentCyan.opacity(0.35), radius: 8, y: 2)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 3) {
                    Text(l10n.t(mode.titleKey))
                        .font(AppFont.display(21, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(l10n.t(mode.subtitleKey))
                        .font(AppFont.ui(14, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.95))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(iconTint.opacity(0.8))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(gradient ? AnyShapeStyle(AppColors.drawCardGradient) : AnyShapeStyle(AppColors.surfaceCard))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(AppColors.accentCyan.opacity(gradient ? 0.5 : 0.2), lineWidth: 1.5)
                    )
                    .shadow(color: AppColors.accentCyan.opacity(gradient ? 0.3 : 0.15), radius: 12, y: 4)
                    .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
            }
        }
        .buttonStyle(.plain)
    }
}

struct HowToPlaySheet: View {
    var mode: GameMode = .classic

    @Environment(\.dismiss) private var dismiss
    @Bindable private var l10n = LocalizationManager.shared
    @State private var page = 0

    private func howtoKey(_ step: Int, _ part: String) -> String {
        "howto.\(mode.rawValue).\(step).\(part)"
    }

    private var pages: [(visual: HowtoVisual, title: String, body: String, extra: String?)] {
        let prefix = "howto_\(mode.rawValue)"
        return [
            (.modeHero, l10n.t(howtoKey(1, "title")), l10n.t(howtoKey(1, "body")), nil),
            (.image("\(prefix)_role"), l10n.t(howtoKey(2, "title")), l10n.t(howtoKey(2, "body")), nil),
            (.image("\(prefix)_clue"), l10n.t(howtoKey(3, "title")), l10n.t(howtoKey(3, "body")), nil),
            (
                .image("\(prefix)_vote"),
                l10n.t(howtoKey(4, "title")),
                l10n.t(howtoKey(4, "body")),
                l10n.t(howtoKey(4, "warning"))
            )
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppColors.textSecondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 6)

            VStack(spacing: 8) {
                ScreenTitle(text: l10n.t("round.howToTitle"))

                HStack(spacing: 8) {
                    Image(mode.iconImageName)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                    Text(l10n.t(mode.titleKey))
                        .font(AppFont.display(14, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppColors.surfaceCard)
                        .overlay(Capsule().stroke(AppColors.accentCyan.opacity(0.35), lineWidth: 1))
                )

                stepRail
            }
            .padding(.bottom, 4)

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    tutorialPage(pages[index], index: index)
                        .tag(index)
                        .contentShape(Rectangle())
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .id(mode)

            Button {
                Haptics.light()
                if page < pages.count - 1 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { page += 1 }
                } else {
                    dismiss()
                }
            } label: {
                Text(page < pages.count - 1 ? l10n.t("common.next") : l10n.t("common.gotIt"))
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OceanBackground())
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .onAppear {
            page = 0
            Haptics.light()
        }
    }

    private var stepRail: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(
                        index == page
                            ? AppColors.accentYellow
                            : index < page
                                ? AppColors.accentCyan.opacity(0.85)
                                : Color.white.opacity(0.25)
                    )
                    .frame(width: index == page ? 26 : 10, height: 8)
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
    }

    private func tutorialPage(
        _ page: (visual: HowtoVisual, title: String, body: String, extra: String?),
        index: Int
    ) -> some View {
        GeometryReader { geo in
            let isFinale = index == 3
            let visualHeight = geo.size.height * (isFinale ? 0.26 : 0.44)
            let gap = max(geo.size.height * 0.025, 8)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                visualBlock(page.visual, height: visualHeight)

                Spacer().frame(height: gap)

                Text("\(index + 1)")
                    .font(AppFont.display(14, weight: .black))
                    .foregroundStyle(AppColors.textOnLight)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(AppColors.accentYellow))

                Spacer().frame(height: gap * 0.7)

                Text(page.title)
                    .font(AppFont.display(isFinale ? 22 : 24, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                    .lineLimit(2)

                Spacer().frame(height: 6)

                Text(page.body)
                    .font(AppFont.ui(isFinale ? 13 : 15, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .lineLimit(isFinale ? 3 : 4)

                if isFinale {
                    Spacer().frame(height: gap)

                    finaleBoard(
                        warning: page.extra,
                        crewText: l10n.t("howto.win"),
                        imposterText: l10n.t("howto.lose")
                    )
                } else if let extra = page.extra {
                    Spacer().frame(height: gap)
                    tipBanner(extra)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func tipBanner(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColors.accentYellow)
                .padding(.top, 1)

            Text(text)
                .font(AppFont.ui(12, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.85)
                .lineLimit(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.surfaceCard.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColors.accentYellow.opacity(0.28), lineWidth: 1)
                )
        )
    }

    private func finaleBoard(warning: String?, crewText: String, imposterText: String) -> some View {
        VStack(spacing: 8) {
            finalePath(
                icon: "person.3.fill",
                tint: AppColors.stateSuccess,
                title: l10n.t("howto.crewPath"),
                detail: crewText
            )

            Text(l10n.t("howto.or"))
                .font(AppFont.ui(10, weight: .bold))
                .foregroundStyle(AppColors.textSecondary.opacity(0.65))

            finalePath(
                icon: "theatermasks.fill",
                tint: AppColors.stateDanger,
                title: l10n.t("howto.imposterPath"),
                detail: imposterText
            )

            if let warning, !warning.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppColors.accentYellow)
                    Text(warning)
                        .font(AppFont.ui(11, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .minimumScaleFactor(0.85)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surfaceCard.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppColors.accentCyan.opacity(0.45),
                                    AppColors.accentYellow.opacity(0.2),
                                    AppColors.stateDanger.opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
    }

    private func finalePath(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppFont.display(16, weight: .black))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(detail)
                    .font(AppFont.ui(14, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.surfaceCardElevated.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(tint.opacity(0.28), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func visualBlock(_ visual: HowtoVisual, height: CGFloat) -> some View {
        switch visual {
        case .modeHero:
            let iconSize = min(height * 0.72, 160)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppColors.accentCyan.opacity(0.35), .clear],
                            center: .center,
                            startRadius: 12,
                            endRadius: height * 0.55
                        )
                    )
                    .frame(width: height, height: height)

                Image(mode.iconImageName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .shadow(color: AppColors.accentCyan.opacity(0.4), radius: 14, y: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)

        case .image(let name):
            Image(name)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .padding(.horizontal, 12)
        }
    }
}

private enum HowtoVisual {
    case modeHero
    case image(String)
}

private extension View {
    @ViewBuilder
    func homeScrollEdgeFix() -> some View {
        if #available(iOS 26.0, *) {
            self.scrollEdgeEffectHidden(true, for: .bottom)
        } else {
            self
        }
    }
}

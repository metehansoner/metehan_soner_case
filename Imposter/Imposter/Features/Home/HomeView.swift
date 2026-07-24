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
                headerCircleButton(systemName: "xmark") {
                    Haptics.light()
                    dismiss()
                }
            } else if showsProfileButton {
                headerCircleButton(systemName: "person.crop.circle.fill") {
                    onProfile?()
                }
            }

            Text(l10n.t("app.name").uppercased())
                .font(AppFont.display(26, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .shadow(color: AppColors.surfaceCard.opacity(0.9), radius: 0, x: 0, y: 3)
                .shadow(color: AppColors.accentCyan.opacity(0.45), radius: 10, y: 0)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 8)

            headerCircleButton(systemName: "gearshape.fill") {
                Haptics.light()
                showSettings = true
            }

            headerCircleButton(systemName: "info.circle") {
                Haptics.light()
                showInfo = true
            }
        }
    }

    private func headerCircleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 42, height: 42)
                .background(Circle().fill(AppColors.surfaceCard.opacity(0.85)))
                .overlay(Circle().stroke(AppColors.accentCyan.opacity(0.55), lineWidth: 1.5))
                .shadow(color: AppColors.accentCyan.opacity(0.45), radius: 8, y: 0)
        }
        .buttonStyle(.plain)
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
                        .font(AppFont.ui(22, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)

                    Text(subtitle)
                        .font(AppFont.ui(14))
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(AppColors.textSecondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            Text(l10n.t("round.howToTitle"))
                .font(AppFont.display(24, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Group {
                bullet(l10n.t("round.howTo1"))
                bullet(l10n.t("round.howTo2"))
                bullet(l10n.t("round.howTo3"))
            }

            Spacer()

            Button {
                Haptics.light()
                dismiss()
            } label: {
                Text(l10n.t("common.gotIt"))
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(OceanBackground())
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(32)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(AppColors.accentCyan)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            Text(text)
                .font(AppFont.ui(15))
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

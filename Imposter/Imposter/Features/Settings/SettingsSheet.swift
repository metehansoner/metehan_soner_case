import SwiftUI
import UIKit

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var settings = AppSettingsStore.shared
    @Bindable private var l10n = LocalizationManager.shared

    @State private var showLanguage = false
    @State private var copiedID = false

    private let supportEmail = "support@imposterparty.app"
    private let privacyURL = URL(string: "https://imposterparty.app/privacy")!
    private let termsURL = URL(string: "https://imposterparty.app/terms")!

    /// Fits settings content without scrolling on typical phones.
    private let settingsDetentHeight: CGFloat = 520

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppColors.textSecondary.opacity(0.45))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 14)

            Text(l10n.t("settings.title"))
                .font(AppFont.display(30, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            VStack(spacing: 2) {
                settingsRow(title: l10n.t("settings.language"), systemImage: "globe") {
                    Haptics.light()
                    showLanguage = true
                }

                settingsRow(title: l10n.t("common.restore"), systemImage: "arrow.clockwise") {
                    Haptics.light()
                    Task { await SubscriptionStore.shared.restore() }
                }

                settingsRow(title: l10n.t("settings.contact"), systemImage: "envelope") {
                    Haptics.light()
                    openMail()
                }

                Link(destination: privacyURL) {
                    settingsRowLabel(title: l10n.t("settings.privacy"), systemImage: "shield")
                }
                .simultaneousGesture(TapGesture().onEnded { Haptics.light() })

                Link(destination: termsURL) {
                    settingsRowLabel(title: l10n.t("settings.terms"), systemImage: "doc.text")
                }
                .simultaneousGesture(TapGesture().onEnded { Haptics.light() })

                vibrationRow
            }
            .padding(.horizontal, 12)

            VStack(spacing: 10) {
                Button {
                    UIPasteboard.general.string = settings.userId
                    Haptics.light()
                    copiedID = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedID = false }
                } label: {
                    VStack(spacing: 4) {
                        Text(l10n.t("settings.userId", ["id": settings.userId]))
                            .font(AppFont.ui(12, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        if copiedID {
                            Text(l10n.t("common.copied"))
                                .font(AppFont.ui(11, weight: .bold))
                                .foregroundStyle(AppColors.accentCyan)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.light()
                    dismiss()
                } label: {
                    Text(l10n.t("common.close"))
                }
                .buttonStyle(SecondaryCapsuleButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 20)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(sheetBackground)
        .presentationDetents([.height(settingsDetentHeight)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .onAppear { Haptics.light() }
        .sheet(isPresented: $showLanguage) {
            LanguageSheet()
        }
    }

    private var vibrationRow: some View {
        HStack {
            Text(l10n.t("settings.vibration"))
                .font(AppFont.display(18, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 8)
            OnOffToggle(isOn: Binding(
                get: { settings.hapticsEnabled },
                set: { newValue in
                    settings.hapticsEnabled = newValue
                    if newValue { Haptics.selection() }
                }
            ))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func settingsRow(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            settingsRowLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func settingsRowLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(AppFont.display(18, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 8)
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppColors.textPrimary.opacity(0.95))
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var sheetBackground: some View {
        LinearGradient(
            colors: [AppColors.bgPrimaryMid, AppColors.bgPrimary],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func openMail() {
        let url = URL(string: "mailto:\(supportEmail)")!
        UIApplication.shared.open(url)
    }
}

struct OnOffToggle: View {
    @Binding var isOn: Bool
    @Bindable private var l10n = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 0) {
            toggleSegment(title: l10n.t("common.off"), selected: !isOn) {
                isOn = false
            }
            toggleSegment(title: l10n.t("common.on"), selected: isOn) {
                isOn = true
            }
        }
        .padding(3)
        .background(
            Capsule().fill(AppColors.surfaceCard)
        )
    }

    private func toggleSegment(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.display(13, weight: .bold))
                .foregroundStyle(selected ? AppColors.textOnLight : AppColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(selected ? AppColors.btnPrimaryBg : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

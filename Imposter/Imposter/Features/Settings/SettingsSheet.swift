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

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppColors.textSecondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)

            Text(l10n.t("settings.title"))
                .font(AppFont.display(26, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.bottom, 20)

            VStack(spacing: 4) {
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
            .padding(.horizontal, 8)

            Spacer(minLength: 16)

            Text(l10n.t("settings.userId", ["id": shortUserID]))
                .font(AppFont.ui(12))
                .foregroundStyle(AppColors.textSecondary.opacity(0.8))
                .padding(.bottom, 8)
                .onLongPressGesture {
                    UIPasteboard.general.string = settings.userId
                    Haptics.light()
                    copiedID = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedID = false }
                }

            if copiedID {
                Text("Copied")
                    .font(AppFont.ui(11, weight: .semibold))
                    .foregroundStyle(AppColors.accentCyan)
                    .padding(.bottom, 8)
            }

            Button {
                Haptics.light()
                dismiss()
            } label: {
                Text(l10n.t("common.close"))
            }
            .buttonStyle(SecondaryCapsuleButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(sheetBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .onAppear { Haptics.light() }
        .sheet(isPresented: $showLanguage) {
            LanguageSheet()
        }
    }

    private var shortUserID: String {
        let id = settings.userId
        guard id.count > 12 else { return id }
        return String(id.prefix(8)) + "…"
    }

    private var vibrationRow: some View {
        HStack {
            Text(l10n.t("settings.vibration"))
                .font(AppFont.ui(17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            OnOffToggle(isOn: Binding(
                get: { settings.hapticsEnabled },
                set: { newValue in
                    settings.hapticsEnabled = newValue
                    if newValue { Haptics.selection() }
                }
            ))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func settingsRow(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            settingsRowLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func settingsRowLabel(title: String, systemImage: String) -> some View {
        HStack {
            Text(title)
                .font(AppFont.ui(17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary.opacity(0.9))
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
                .font(AppFont.ui(13, weight: .bold))
                .foregroundStyle(selected ? AppColors.textOnLight : AppColors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(selected ? AppColors.btnPrimaryBg : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

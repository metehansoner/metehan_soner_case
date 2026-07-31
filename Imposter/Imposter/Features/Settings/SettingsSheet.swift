import SwiftUI
import UIKit

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var settings = AppSettingsStore.shared
    @Bindable private var l10n = LocalizationManager.shared

    @State private var showLanguage = false
    @State private var copiedID = false
    @State private var notificationsToggle = false

    private let supportEmail = "teamo.touch@gmail.com"
    private let privacyURL = URL(string: "https://teamo-couple.web.app/imposter-party-privacy.html")!
    private let termsURL = URL(string: "https://teamo-couple.web.app/imposter-party-terms.html")!

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                Capsule()
                    .fill(AppColors.textSecondary.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 10)

                ScreenTitle(text: l10n.t("settings.title"))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 14)

                ScrollView {
                    VStack(spacing: 14) {
                        settingsGroup(title: l10n.t("settings.groupPlay")) {
                            navRow(
                                title: l10n.t("settings.language"),
                                subtitle: languageSubtitle,
                                systemImage: "globe"
                            ) {
                                Haptics.light()
                                showLanguage = true
                            }

                            Divider().overlay(AppColors.accentCyan.opacity(0.12))

                            vibrationRow

                            Divider().overlay(AppColors.accentCyan.opacity(0.12))

                            notificationsRow
                        }

                        settingsGroup(title: l10n.t("settings.groupAccount")) {
                            navRow(
                                title: l10n.t("common.restore"),
                                subtitle: l10n.t("settings.restoreHint"),
                                systemImage: "arrow.clockwise.circle.fill"
                            ) {
                                Haptics.light()
                                Task { await SubscriptionStore.shared.restore() }
                            }

                            Divider().overlay(AppColors.accentCyan.opacity(0.12))

                            navRow(
                                title: l10n.t("settings.contact"),
                                subtitle: supportEmail,
                                systemImage: "envelope.fill"
                            ) {
                                Haptics.light()
                                openMail()
                            }
                        }

                        settingsGroup(title: l10n.t("settings.groupLegal")) {
                            Link(destination: privacyURL) {
                                navRowLabel(
                                    title: l10n.t("settings.privacy"),
                                    subtitle: l10n.t("settings.privacyHint"),
                                    systemImage: "hand.raised.fill"
                                )
                            }
                            .simultaneousGesture(TapGesture().onEnded { Haptics.light() })

                            Divider().overlay(AppColors.accentCyan.opacity(0.12))

                            Link(destination: termsURL) {
                                navRowLabel(
                                    title: l10n.t("settings.terms"),
                                    subtitle: l10n.t("settings.termsHint"),
                                    systemImage: "doc.text.fill"
                                )
                            }
                            .simultaneousGesture(TapGesture().onEnded { Haptics.light() })
                        }

                        userIdCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .scrollIndicators(.hidden)

                Button {
                    Haptics.light()
                    dismiss()
                } label: {
                    Text(l10n.t("common.done"))
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 22)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .onAppear {
            Haptics.light()
            notificationsToggle = settings.notificationsEnabled
        }
        .onChange(of: settings.notificationsEnabled) { _, enabled in
            notificationsToggle = enabled
        }
        .task {
            await NotificationService.syncPreferenceWithSystem()
            notificationsToggle = settings.notificationsEnabled
        }
        .sheet(isPresented: $showLanguage) {
            LanguageSheet()
        }
    }

    private var languageSubtitle: String {
        LocalizationManager.languageDisplayName(l10n.localeCode) ?? l10n.localeCode.uppercased()
    }

    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFont.section(13))
                .foregroundStyle(AppColors.accentYellow)
                .textCase(.uppercase)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppColors.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(AppColors.accentCyan.opacity(0.16), lineWidth: 1)
                    )
            )
        }
    }

    private var vibrationRow: some View {
        HStack(spacing: 12) {
            iconBadge(systemImage: "waveform")

            VStack(alignment: .leading, spacing: 2) {
                Text(l10n.t("settings.vibration"))
                    .font(AppFont.display(17, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(l10n.t("settings.vibrationHint"))
                    .font(AppFont.ui(12, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 8)

            OnOffToggle(isOn: Binding(
                get: { settings.hapticsEnabled },
                set: { newValue in
                    settings.hapticsEnabled = newValue
                    if newValue { Haptics.selection() }
                }
            ))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var notificationsRow: some View {
        HStack(spacing: 12) {
            iconBadge(systemImage: "bell.fill")

            VStack(alignment: .leading, spacing: 2) {
                Text(l10n.t("settings.notifications"))
                    .font(AppFont.display(17, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(l10n.t("settings.notificationsHint"))
                    .font(AppFont.ui(12, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 8)

            OnOffToggle(isOn: Binding(
                get: { notificationsToggle },
                set: { newValue in
                    guard newValue != notificationsToggle else { return }
                    Haptics.selection()
                    notificationsToggle = newValue
                    Task { @MainActor in
                        let result = await NotificationService.handleToggle(enabled: newValue)
                        notificationsToggle = settings.notificationsEnabled
                        if result == .openSystemSettings {
                            NotificationService.openAppNotificationSettings()
                        }
                    }
                }
            ))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func navRow(
        title: String,
        subtitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            navRowLabel(title: title, subtitle: subtitle, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func navRowLabel(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            iconBadge(systemImage: systemImage)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.display(17, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(AppFont.ui(12, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColors.accentCyan.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func iconBadge(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(AppColors.accentCyan)
            .frame(width: 36, height: 36)
            .background(Circle().fill(AppColors.surfaceCardElevated))
    }

    private var userIdCard: some View {
        Button {
            UIPasteboard.general.string = settings.userId
            Haptics.light()
            copiedID = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedID = false }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.accentYellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.t("settings.userIdLabel"))
                        .font(AppFont.ui(12, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .textCase(.uppercase)
                    Text(settings.userId)
                        .font(AppFont.ui(13, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 4)

                Text(copiedID ? l10n.t("common.copied") : l10n.t("settings.copyId"))
                    .font(AppFont.ui(12, weight: .bold))
                    .foregroundStyle(copiedID ? AppColors.stateSuccess : AppColors.btnPrimaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(copiedID ? AppColors.surfaceCardElevated : AppColors.btnPrimaryBg)
                    )
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppColors.surfaceCard.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppColors.accentYellow.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
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
            Capsule().fill(AppColors.surfaceCardElevated)
        )
    }

    private func toggleSegment(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.display(12, weight: .bold))
                .foregroundStyle(selected ? AppColors.textOnLight : AppColors.textSecondary)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(selected ? AppColors.btnPrimaryBg : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

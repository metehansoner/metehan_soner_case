import SwiftUI
import StoreKit

struct PaywallView: View {
    var onFinished: () -> Void

    @Bindable private var store = SubscriptionStore.shared
    @Bindable private var l10n = LocalizationManager.shared

    private let privacyURL = URL(string: "https://imposterparty.app/privacy")!
    private let termsURL = URL(string: "https://imposterparty.app/terms")!

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 18) {
                        Image("paywall_hero")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .padding(.top, 12)

                        Text(l10n.t("paywall.title"))
                            .font(AppFont.display(28, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                        VStack(spacing: 10) {
                            planRow(
                                plan: .freeTrial,
                                title: l10n.t("paywall.freeTrial"),
                                subtitle: l10n.t("paywall.cancelAnytime"),
                                badge: nil
                            )
                            planRow(
                                plan: .yearly,
                                title: l10n.t("paywall.yearly"),
                                subtitle: "₺2.499,99/year · ₺47,95/week",
                                badge: l10n.t("paywall.bestDeal")
                            )
                            planRow(
                                plan: .weekly,
                                title: l10n.t("paywall.weekly"),
                                subtitle: "₺499,99/week · " + l10n.t("paywall.cancelAnytime"),
                                badge: l10n.t("paywall.mostPopular")
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 24)
                }

                VStack(spacing: 12) {
                    Button {
                        Task {
                            await store.purchaseSelectedPlan()
                            if store.isPremium {
                                finish(markSeen: true)
                            }
                        }
                    } label: {
                        HStack {
                            if store.isPurchasing {
                                ProgressView().tint(AppColors.textOnLight)
                            }
                            Text(ctaTitle)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(enabled: !store.isPurchasing))
                    .disabled(store.isPurchasing)

                    HStack(spacing: 18) {
                        Link(l10n.t("common.terms"), destination: termsURL)
                        Link(l10n.t("common.privacy"), destination: privacyURL)
                        Button {
                            finish(markSeen: true)
                        } label: {
                            Text(l10n.t("common.skip"))
                                .underline()
                        }
                        .buttonStyle(.plain)
                        Button {
                            Task { await store.restore() }
                        } label: {
                            Text(l10n.t("common.restore"))
                        }
                        .buttonStyle(.plain)
                    }
                    .font(AppFont.ui(12, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)

                    if let statusMessage = store.statusMessage {
                        Text(statusMessage)
                            .font(AppFont.ui(12))
                            .foregroundStyle(AppColors.stateDanger)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .onAppear { Haptics.light() }
    }

    private var ctaTitle: String {
        store.selectedPlan == .freeTrial ? l10n.t("paywall.tryFree") : l10n.t("paywall.continue")
    }

    private func finish(markSeen: Bool) {
        if markSeen { store.paywallSeen = true }
        Haptics.medium()
        onFinished()
    }

    private func planRow(plan: SubscriptionPlan, title: String, subtitle: String, badge: String?) -> some View {
        let selected = store.selectedPlan == plan
        return Button {
            Haptics.selection()
            store.selectedPlan = plan
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(AppFont.ui(16, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    if let badge {
                        Text(badge)
                            .font(AppFont.ui(11, weight: .bold))
                            .foregroundStyle(AppColors.textOnLight)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(AppColors.accentYellow))
                    }
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selected ? AppColors.accentCyan : AppColors.textSecondary)
                }
                Text(subtitle)
                    .font(AppFont.ui(13))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppColors.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selected ? AppColors.accentCyan : AppColors.accentCyan.opacity(0.15), lineWidth: selected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct RateUsSheet: View {
    var onClose: () -> Void

    @Bindable private var l10n = LocalizationManager.shared
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button {
                    close()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(8)
                }
            }

            Image("rate_us")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxHeight: 160)

            Text(l10n.t("rate.title"))
                .font(AppFont.display(24, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(l10n.t("rate.body"))
                .font(AppFont.ui(14))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(AppColors.accentCyan)
                Text(l10n.t("rate.incentive"))
                    .font(AppFont.ui(13, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColors.accentCyan.opacity(0.5), lineWidth: 1)
            )

            Button {
                Haptics.success()
                SubscriptionStore.shared.ratePrompted = true
                requestReview()
                onClose()
            } label: {
                Text(l10n.t("rate.cta"))
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.surfaceCard)
        )
        .padding(.horizontal, 20)
        .presentationDetents([.medium])
        .presentationBackground(.clear)
    }

    private func close() {
        SubscriptionStore.shared.ratePrompted = true
        Haptics.light()
        onClose()
    }
}

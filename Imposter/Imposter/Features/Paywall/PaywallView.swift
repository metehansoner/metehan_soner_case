import SwiftUI
import StoreKit

enum PaywallPresentation {
    /// First paywall after onboarding — bottom Skip link.
    case afterOnboarding
    /// Locked content / later opens — no Skip; X appears after delay.
    case modal
}

struct PaywallView: View {
    var presentation: PaywallPresentation = .afterOnboarding
    var onFinished: () -> Void

    @Bindable private var store = SubscriptionStore.shared
    @Bindable private var l10n = LocalizationManager.shared

    @State private var showCloseButton = false

    private let privacyURL = URL(string: "https://imposterparty.app/privacy")!
    private let termsURL = URL(string: "https://imposterparty.app/terms")!

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                Image("paywall_hero")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                    .layoutPriority(1)

                Text(l10n.t("paywall.title"))
                    .font(AppFont.display(24, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
                    .lineLimit(2)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                VStack(spacing: 8) {
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

                VStack(spacing: 10) {
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

                    HStack(spacing: 16) {
                        Link(l10n.t("common.terms"), destination: termsURL)
                        Link(l10n.t("common.privacy"), destination: privacyURL)
                        if presentation == .afterOnboarding {
                            Button {
                                finish(markSeen: true)
                            } label: {
                                Text(l10n.t("common.skip"))
                                    .underline()
                            }
                            .buttonStyle(.plain)
                        }
                        Button {
                            Task { await store.restore() }
                        } label: {
                            Text(l10n.t("common.restore"))
                        }
                        .buttonStyle(.plain)
                    }
                    .font(AppFont.ui(12, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)

                    if let statusMessage = store.statusMessage {
                        Text(statusMessage)
                            .font(AppFont.ui(12))
                            .foregroundStyle(AppColors.stateDanger)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 18)
            }
        }
        .overlay(alignment: .topTrailing) {
            if presentation == .modal, showCloseButton {
                HeaderCircleIconButton(systemName: "xmark") {
                    finish(markSeen: true)
                }
                .padding(.top, 6)
                .padding(.trailing, 14)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .onAppear { Haptics.light() }
        .task(id: presentation) {
            guard presentation == .modal else {
                showCloseButton = false
                return
            }
            showCloseButton = false
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                showCloseButton = true
            }
        }
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
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.ui(15, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(AppFont.ui(12))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(selected ? AppColors.accentCyan : AppColors.textSecondary)
                    .transaction { $0.animation = nil }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.surfaceCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        selected ? AppColors.accentCyan : AppColors.accentCyan.opacity(0.18),
                        lineWidth: 2
                    )
                    .animation(.easeInOut(duration: 0.2), value: selected)
            )
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(AppFont.ui(10, weight: .bold))
                        .foregroundStyle(AppColors.textOnLight)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppColors.accentYellow))
                        .overlay(Capsule().stroke(AppColors.bgPrimary.opacity(0.15), lineWidth: 1))
                        .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                        .offset(x: -12, y: -9)
                        .opacity(selected ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: selected)
                        .allowsHitTesting(false)
                }
            }
            // Same top inset on every plan so selection never shifts the stack.
            .padding(.top, 8)
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
                    .font(AppFont.ui(13, weight: .bold))
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

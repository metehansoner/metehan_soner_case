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

    private let privacyURL = URL(string: "https://teamo-couple.web.app/imposter-party-privacy.html")!
    private let termsURL = URL(string: "https://teamo-couple.web.app/imposter-party-terms.html")!

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                Text(l10n.t("paywall.vipBadge"))
                    .font(AppFont.ui(12, weight: .bold))
                    .foregroundStyle(AppColors.textOnLight)
                    .textCase(.uppercase)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(AppColors.accentYellow))
                    .padding(.top, 14)

                Image("paywall_hero")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 250)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                Text(l10n.t("paywall.headline"))
                    .font(AppFont.display(28, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 22)
                    .padding(.top, 6)

                Text(l10n.t("paywall.title"))
                    .font(AppFont.ui(14, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    .padding(.bottom, 12)

                benefitsList
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                VStack(spacing: 8) {
                    planRow(
                        plan: .yearly,
                        title: l10n.t("paywall.yearly"),
                        subtitle: yearlySubtitle,
                        badge: l10n.t("paywall.bestDeal")
                    )
                    planRow(
                        plan: .weekly,
                        title: l10n.t("paywall.weekly"),
                        subtitle: weeklySubtitle,
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
                            Text(l10n.t("paywall.continue"))
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
        .task {
            if !store.productsLoaded {
                await store.loadProducts()
            }
        }
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

    private var yearlySubtitle: String {
        if let price = store.displayPrice(for: .yearly) {
            if let perWeek = store.perWeekPrice(for: .yearly) {
                return l10n.t("paywall.perYearWeek", ["year": price, "week": perWeek])
            }
            return l10n.t("paywall.perYear", ["year": price])
        }
        return l10n.t("paywall.loadingPrice")
    }

    private var weeklySubtitle: String {
        if let price = store.displayPrice(for: .weekly) {
            return l10n.t("paywall.perWeek", ["week": price]) + " · " + l10n.t("paywall.cancelAnytime")
        }
        return l10n.t("paywall.loadingPrice")
    }

    private var benefitsList: some View {
        VStack(spacing: 8) {
            benefitChip(systemName: "square.grid.2x2.fill", key: "paywall.benefit1")
            benefitChip(systemName: "sparkles", key: "paywall.benefit2")
            benefitChip(systemName: "bolt.fill", key: "paywall.benefit3")
        }
    }

    private func benefitChip(systemName: String, key: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppColors.accentCyan)
                .frame(width: 34, height: 34)
                .background(Circle().fill(AppColors.surfaceCardElevated))
            Text(l10n.t(key))
                .font(AppFont.ui(14, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surfaceCard.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppColors.accentCyan.opacity(0.18), lineWidth: 1)
                )
        )
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
        VStack(spacing: 0) {
            Capsule()
                .fill(AppColors.textSecondary.opacity(0.45))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 8)

            HStack {
                Spacer()
                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(AppColors.surfaceCardElevated))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            Image("rate_us")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxHeight: 140)
                .padding(.horizontal, 24)

            Text(l10n.t("rate.title"))
                .font(AppFont.display(26, weight: .black))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            Text(l10n.t("rate.body"))
                .font(AppFont.ui(14, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 6)

            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundStyle(AppColors.accentYellow)
                Text(l10n.t("rate.incentive"))
                    .font(AppFont.ui(13, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.surfaceCardElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppColors.accentYellow.opacity(0.4), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.top, 14)

            Spacer(minLength: 8)

            Button {
                Haptics.success()
                SubscriptionStore.shared.ratePrompted = true
                requestReview()
                onClose()
            } label: {
                Text(l10n.t("rate.cta"))
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            OceanBackground()
                .ignoresSafeArea()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .presentationBackground {
            OceanBackground()
                .ignoresSafeArea()
        }
    }

    private func close() {
        SubscriptionStore.shared.ratePrompted = true
        Haptics.light()
        onClose()
    }
}

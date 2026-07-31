import SwiftUI

/// Theme unlock gate: one-round ad unlock or yearly Party Pass.
struct CategoryPaywallView: View {
    var onClose: () -> Void
    var onWatchAd: () -> Void
    var onPurchaseYearly: () -> Void
    var adErrorMessage: String? = nil

    @Bindable private var store = SubscriptionStore.shared
    @Bindable private var l10n = LocalizationManager.shared
    @Bindable private var ads = RewardedAdService.shared

    private let privacyURL = URL(string: "https://teamo-couple.web.app/imposter-party-privacy.html")!
    private let termsURL = URL(string: "https://teamo-couple.web.app/imposter-party-terms.html")!

    var body: some View {
        ZStack {
            OceanBackground()
                .opacity(0.92)
                .ignoresSafeArea()

            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: 0) {
                HStack {
                    Text(l10n.t("catPaywall.badge"))
                        .font(AppFont.ui(12, weight: .bold))
                        .foregroundStyle(AppColors.textOnLight)
                        .textCase(.uppercase)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(AppColors.accentYellow))

                    Spacer()

                    Button {
                        Haptics.light()
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppColors.surfaceCardElevated))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Image("paywall_category_hero")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 140)
                    .padding(.top, 8)
                    .shadow(color: AppColors.accentCyan.opacity(0.35), radius: 18, y: 6)

                Text(l10n.t("catPaywall.title"))
                    .font(AppFont.display(28, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 10)

                Text(l10n.t("catPaywall.subtitle"))
                    .font(AppFont.ui(14, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 6)
                    .padding(.bottom, 18)

                VStack(spacing: 12) {
                    watchAdCard
                    yearlyCard
                }
                .padding(.horizontal, 18)

                if let adErrorMessage, !adErrorMessage.isEmpty {
                    Text(adErrorMessage)
                        .font(AppFont.ui(12, weight: .bold))
                        .foregroundStyle(AppColors.stateDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                }

                footerLinks
                    .padding(.top, 18)
                    .padding(.bottom, 28)
            }
            .frame(maxWidth: 440)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(AppColors.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(AppColors.accentCyan.opacity(0.35), lineWidth: 1.5)
                    )
                    .shadow(color: AppColors.accentCyan.opacity(0.25), radius: 28, y: 10)
            )
            .padding(.horizontal, 18)
        }
        .onAppear { Haptics.light() }
        .task {
            if !store.productsLoaded {
                await store.loadProducts()
            }
        }
    }

    private var watchAdCard: some View {
        Button {
            Haptics.medium()
            onWatchAd()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppColors.accentCyan)
                        .frame(width: 48, height: 48)
                    if ads.isLoading {
                        ProgressView().tint(AppColors.textOnLight)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppColors.textOnLight)
                            .offset(x: 1)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(ads.isLoading ? l10n.t("paywall.adLoading") : l10n.t("catPaywall.watchTitle"))
                        .font(AppFont.display(18, weight: .black))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(l10n.t("catPaywall.watchBody"))
                        .font(AppFont.ui(13, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.accentCyan)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppColors.surfaceCardElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(AppColors.accentCyan.opacity(0.55), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(ads.isLoading)
    }

    private var yearlyCard: some View {
        Button {
            Haptics.medium()
            store.selectedPlan = .yearly
            onPurchaseYearly()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(l10n.t("catPaywall.passBadge"))
                        .font(AppFont.ui(11, weight: .bold))
                        .foregroundStyle(AppColors.textOnLight)
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(AppColors.accentYellow))

                    Spacer()

                    if store.isPurchasing {
                        ProgressView().tint(.white)
                    }
                }

                Text(l10n.t("catPaywall.passTitle"))
                    .font(AppFont.display(22, weight: .black))
                    .foregroundStyle(.white)

                Text(l10n.t("catPaywall.passBody"))
                    .font(AppFont.ui(13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text(yearlyOfferText)
                        .font(AppFont.ui(13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.92))
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppColors.drawCardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: AppColors.accentCyan.opacity(0.4), radius: 16, y: 6)
            )
        }
        .buttonStyle(.plain)
        .disabled(store.isPurchasing)
    }

    private var yearlyOfferText: String {
        if let price = store.displayPrice(for: .yearly) {
            return l10n.t("paywall.perYear", ["year": price])
        }
        return l10n.t("paywall.yearlyOffer")
    }

    private var footerLinks: some View {
        HStack(spacing: 18) {
            Link(l10n.t("common.terms"), destination: termsURL)
            Link(l10n.t("common.privacy"), destination: privacyURL)
            Button {
                Task { await store.restore() }
            } label: {
                Text(l10n.t("common.restore"))
            }
            .buttonStyle(.plain)
        }
        .font(AppFont.ui(12, weight: .bold))
        .foregroundStyle(AppColors.textSecondary)
    }
}

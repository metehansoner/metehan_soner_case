import SwiftUI

/// Compact category unlock sheet: watch-ad (stub) + yearly premium.
struct CategoryPaywallView: View {
    var onClose: () -> Void
    var onWatchAd: () -> Void
    var onPurchaseYearly: () -> Void

    @Bindable private var store = SubscriptionStore.shared
    @Bindable private var l10n = LocalizationManager.shared

    private let privacyURL = URL(string: "https://imposterparty.app/privacy")!
    private let termsURL = URL(string: "https://imposterparty.app/terms")!

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        Haptics.light()
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                Image("paywall_category_hero")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: 200, maxHeight: 150)
                    .padding(.top, 4)

                titleBlock
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 18)

                watchAdButton
                    .padding(.horizontal, 20)

                yearlyCard
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                footerLinks
                    .padding(.top, 16)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(hex: 0x1A1A1F))
            )
            .padding(.horizontal, 22)
        }
        .onAppear { Haptics.light() }
    }

    private var titleBlock: some View {
        let highlight = l10n.t("paywall.unlockHighlight")
        let rest = l10n.t("paywall.unlockRest")

        return Group {
            if rest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(highlight)
                    .foregroundStyle(AppColors.accentYellow)
            } else {
                (
                    Text(highlight)
                        .foregroundStyle(AppColors.accentYellow)
                    + Text(" ")
                    + Text(rest)
                        .foregroundStyle(AppColors.textPrimary)
                )
            }
        }
        .font(AppFont.display(28, weight: .black))
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var watchAdButton: some View {
        Button {
            Haptics.medium()
            // Ad SDK wiring comes later — callback is the hook.
            onWatchAd()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.black)
                        .offset(x: 1)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.t("paywall.watchAd"))
                        .font(AppFont.ui(16, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(l10n.t("paywall.watchAdSubtitle"))
                        .font(AppFont.ui(12))
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Capsule()
                    .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var yearlyCard: some View {
        Button {
            Haptics.medium()
            store.selectedPlan = .yearly
            onPurchaseYearly()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.white)
                    Text(l10n.t("paywall.getUnlimited"))
                        .font(AppFont.ui(15, weight: .bold))
                        .foregroundStyle(.white)
                }

                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.t("paywall.freeTrialBadge"))
                            .font(AppFont.ui(10, weight: .bold))
                            .foregroundStyle(AppColors.textOnLight)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white))

                        Text(l10n.t("paywall.yearly"))
                            .font(AppFont.display(20, weight: .black))
                            .foregroundStyle(.white)

                        Text(l10n.t("paywall.yearlyOffer"))
                            .font(AppFont.ui(12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                )
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xFF3B5C), Color(hex: 0xFF6B9D)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(store.isPurchasing)
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
        .foregroundStyle(Color.white.opacity(0.55))
    }
}

import SwiftUI

/// Plan kartı — 03-onboarding-paywall.md §2 madde 4, `paywall.html` `.plan`.
///
/// Bilet koçanı görünümü: ortada perfore çizgi, iki yanda tırtık çentiği.
/// Büyük rakam her zaman **kendi döneminin tam tutarı**, haftalık karşılık
/// altta — üç kart aynı dille konuşmazsa karşılaştırma imkânsız hâle geliyor.
struct PlanCard: View {
    let offer: SubscriptionStore.PlanOffer
    let isSelected: Bool
    let action: () -> Void

    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        Button {
            Haptics.secondaryButton()
            action()
        } label: {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.t("paywall.plan.\(offer.plan.rawValue)"))
                        .font(AppFont.display(15.5, weight: .semibold))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.textCream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let subtitle {
                        Text(subtitle)
                            .font(AppFont.ui(10.5))
                            .foregroundStyle(
                                isSelected ? AppColors.textSecondary : AppColors.textMuted
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                perforation.padding(.horizontal, 13)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(offer.price)
                        .font(AppFont.display(19, weight: .bold))
                        .foregroundStyle(
                            isSelected ? AppColors.surfacePoster : AppColors.accentAmber
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(l10n.t("paywall.plan.\(offer.plan.rawValue).unit"))
                        .font(AppFont.ui(9.5))
                        .foregroundStyle(AppColors.textMuted)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, isSelected ? 12 : 13)
            .padding(.horizontal, isSelected ? 14 : 15)
            .frame(minHeight: 64)
            .background { surface }
            .overlay(alignment: .topTrailing) { band }
            .overlay { notches }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// §03 §4: deneme metni store'dan geliyor. Denemesi olmayan planda haftalık
    /// karşılık yazıyor, haftalık planda alt satır boş kalıyor.
    private var subtitle: String? {
        if let days = offer.trialDays {
            return l10n.t("paywall.plan.trialSub", count: days)
        }
        if let perWeek = offer.pricePerWeek {
            return l10n.t("paywall.plan.perWeek", ["price": perWeek])
        }
        return nil
    }

    private var surface: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: isSelected
                        ? [Color(hex: 0x4A3016).opacity(0.85), Color(hex: 0x261A11).opacity(0.8)]
                        : [AppColors.surfaceCardRaised.opacity(0.9), AppColors.surfaceCard.opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12).strokeBorder(
                    isSelected ? AppColors.accentAmber : AppColors.accentGold.opacity(0.32),
                    lineWidth: isSelected ? 2 : 1
                )
            }
            // Seçili kartın ampulleri yanıyor (§2 madde 4).
            .overlay {
                if isSelected {
                    BulbFrame(countPerEdge: 6, diameter: 3, color: AppColors.accentAmber)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 3)
                }
            }
            .shadow(color: AppColors.accentAmber.opacity(isSelected ? 0.2 : 0), radius: 10, y: 5)
    }

    private var perforation: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: 1)
            .overlay {
                Rectangle()
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
                    .foregroundStyle(AppColors.accentGold.opacity(0.5))
            }
    }

    /// Bilet tırtığı — kartın iki yanında zemin rengiyle oyulmuş yarım daireler.
    private var notches: some View {
        HStack {
            notch
            Spacer(minLength: 0)
            notch
        }
        .padding(.horizontal, -7)
        .allowsHitTesting(false)
    }

    private var notch: some View {
        Circle()
            .fill(AppColors.bgVelvetDeep)
            .frame(width: 13, height: 13)
    }

    @ViewBuilder
    private var band: some View {
        if let days = offer.trialDays {
            bandLabel(l10n.t("paywall.band.trial", count: days), isSaving: false)
        } else if let percent = offer.savingsPercent {
            bandLabel(l10n.t("paywall.band.save", ["percent": "\(percent)"]), isSaving: true)
        }
    }

    private func bandLabel(_ text: String, isSaving: Bool) -> some View {
        Text(text)
            .font(AppFont.ui(8, weight: .bold))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(isSaving ? Color(hex: 0xEAF5EA) : AppColors.textOnPoster)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSaving ? AppColors.stateCorrect : AppColors.accentGold)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            }
            .padding(.trailing, 13)
            .offset(y: -8)
    }

    private var accessibilityLabel: String {
        [
            l10n.t("paywall.plan.\(offer.plan.rawValue)"),
            offer.price,
            l10n.t("paywall.plan.\(offer.plan.rawValue).unit"),
            subtitle,
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}

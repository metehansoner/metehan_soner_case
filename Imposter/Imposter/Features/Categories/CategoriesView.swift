import SwiftUI

struct CategoriesView: View {
    @Bindable var session: GameSession
    var onBack: () -> Void
    var onPlay: () -> Void

    @Bindable private var l10n = LocalizationManager.shared
    @Bindable private var store = SubscriptionStore.shared
    @State private var showSettings = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                ScreenChromeHeader(
                    title: l10n.t("categories.title"),
                    onBack: {
                        Haptics.light()
                        onBack()
                    },
                    onSettings: {
                        Haptics.light()
                        showSettings = true
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(CategoryCatalog.all) { category in
                            categoryCard(category)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 110)
                }

                PlayBar(
                    playTitle: l10n.t("common.play"),
                    summary: l10n.t("categories.selected", ["n": "\(session.selectedCategoryIDs.count)"]),
                    enabled: session.canContinueCategories
                ) {
                    Haptics.medium()
                    onPlay()
                }
            }
        }
        .navigationBarHidden(true)
        .id(store.isPremium)
        .onAppear {
            if session.selectedCategoryIDs.isEmpty {
                session.selectedCategoryIDs.insert("party")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView {
                showPaywall = false
            }
        }
    }

    private func categoryCard(_ category: CategoryDef) -> some View {
        let selected = session.selectedCategoryIDs.contains(category.id)

        return Button {
            if category.isLocked {
                Haptics.warning()
                showPaywall = true
                return
            }
            Haptics.medium()
            if selected {
                session.selectedCategoryIDs.remove(category.id)
            } else {
                session.selectedCategoryIDs.insert(category.id)
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(l10n.t(category.titleKey))
                            .font(AppFont.ui(20, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                        if category.isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        if selected && !category.isLocked {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.accentCyan)
                        }
                    }

                    Text(l10n.t(category.descKey))
                        .font(AppFont.ui(13))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }

                Spacer(minLength: 4)

                Image(category.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 92)
            }
            .padding(.leading, 18)
            .padding(.trailing, 10)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppColors.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(
                                selected && !category.isLocked
                                    ? AppColors.accentCyan
                                    : AppColors.accentCyan.opacity(0.12),
                                lineWidth: selected && !category.isLocked ? 2 : 1
                            )
                    )
                    .opacity(category.isLocked ? 0.72 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

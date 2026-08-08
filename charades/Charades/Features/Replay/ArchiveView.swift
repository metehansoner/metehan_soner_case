import SwiftUI


struct ArchiveView: View {
    @Environment(LocalizationManager.self) private var l10n
    @Environment(AppRouter.self) private var router
    @Environment(AppSettingsStore.self) private var settings

    @State private var model = ArchiveModel()
    @State private var isConfirmingClear = false
    @State private var isConfirmingBulkDelete = false
    @State private var notice: String?

    var body: some View {
        ZStack {
            VelvetBackground()

            VStack(spacing: 0) {
                navBar

                if model.films.isEmpty {
                    emptyState
                } else {
                    list
                }
            }

            if model.isSelecting, !model.selection.isEmpty {
                selectionBar
            }
        }
        .task { model.load(l10n: l10n) }

        .onChange(of: router.path) { _, _ in model.load(l10n: l10n) }
        .overlay(alignment: .bottom) {
            LockedNotice(text: notice) { notice = nil }
        }
        .alert(l10n.t("archive.clear.title"), isPresented: $isConfirmingClear) {
            Button(l10n.t("common.cancel"), role: .cancel) {}
            Button(l10n.t("archive.clear.confirm"), role: .destructive) {
                model.clearAll(l10n: l10n)
            }
        } message: {
            Text(l10n.t("archive.clear.body"))
        }
        .alert(l10n.t("archive.deleteSelected.title"), isPresented: $isConfirmingBulkDelete) {
            Button(l10n.t("common.cancel"), role: .cancel) {}
            Button(l10n.t("common.delete"), role: .destructive) {
                model.deleteSelected(l10n: l10n)
            }
        }
    }


    private var navBar: some View {
        HStack(spacing: 0) {
            BackNavButton(accessibilityLabel: l10n.t("common.back")) {
                router.pop()
            }

            Text(l10n.t("archive.title"))
                .font(AppFont.display(19, weight: .bold))
                .appTracking(2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textCream)
                .frame(maxWidth: .infinity)

            Button {
                Haptics.secondaryButton()
                model.isSelecting.toggle()
            } label: {
                Text(l10n.t(model.isSelecting ? "common.done" : "archive.edit"))
                    .font(AppFont.display(12, weight: .semibold))
                    .appTracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.accentAmber)
                    .frame(minWidth: BackNavButton.hitSide, minHeight: BackNavButton.hitSide)
            }
            .buttonStyle(.plain)
            .opacity(model.films.isEmpty ? 0 : 1)
            .disabled(model.films.isEmpty)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }


    private var list: some View {
        ScrollView {
            VStack(spacing: 0) {
                summaryStrip

                if !settings.archiveNoticeDismissed {
                    privacyStrip
                }

                ForEach(model.films) { film in
                    filmGroup(film)
                }

                storageGroup
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            .padding(.bottom, model.isSelecting ? 92 : 28)
        }
        .scrollIndicators(.hidden)
    }


    private var summaryStrip: some View {
        HStack(spacing: 11) {
            ReelBadge()

            Text(l10n.t("archive.reelCount", count: model.reelCount))
                .font(AppFont.ui(11.5, weight: .semibold))
                .foregroundStyle(AppColors.textCream)

            Text(ArchiveModel.sizeText(model.totalBytes))
                .font(AppFont.ui(11.5))
                .foregroundStyle(AppColors.textSecondary)

            quotaBar

            Text(ArchiveModel.sizeText(ReplayStore.maxTotalBytes))
                .font(AppFont.ui(10))
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 11)
        .background {
            RoundedRectangle(cornerRadius: 11)
                .fill(AppColors.surfaceCardRaised.opacity(0.75))
                .overlay {
                    RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(AppColors.accentGold.opacity(0.2), lineWidth: 1)
                }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var quotaBar: some View {
        GeometryReader { geometry in
            let fraction = min(1, Double(model.totalBytes) / Double(ReplayStore.maxTotalBytes))
            ZStack(alignment: .leading) {
                Capsule().fill(AppColors.textMuted.opacity(0.28))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accentBrass, AppColors.accentAmber],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(3, geometry.size.width * fraction))
            }
        }
        .frame(height: 4)
        .frame(maxWidth: .infinity)
    }


    private var privacyStrip: some View {
        HStack(spacing: 9) {
            Image(systemName: "lock.shield")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.accentTeal)

            Text(l10n.t("archive.privacy"))
                .font(AppFont.ui(10))
                .lineSpacing(2)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                Haptics.secondaryButton()
                settings.dismissArchiveNotice()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.textMuted)
                    .frame(width: 28, height: 28)
                    .tapTarget()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l10n.t("common.close"))
        }
        .padding(.leading, 13)
        .padding(.vertical, 3)
        .background {
            RoundedRectangle(cornerRadius: 9)
                .fill(AppColors.accentTeal.opacity(0.13))
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(AppColors.accentTeal.opacity(0.34), lineWidth: 1)
                }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func filmGroup(_ film: ArchiveModel.Film) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(film.title)
                    .font(AppFont.display(15, weight: .semibold))
                    .appTracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.textCream)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(
                    ArchiveModel.dateText(film.date, localeCode: l10n.localeCode)
                        + " · " + l10n.t("archive.sceneCount", count: film.scenes.count)
                )
                .font(AppFont.ui(9.5, weight: .medium))
                .appTracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textMuted)
                .lineLimit(1)
            }
            .padding(.horizontal, 18)

            ScrollView(.horizontal) {
                HStack(spacing: 11) {
                    ForEach(film.scenes) { reel in
                        ArchiveReelCard(
                            reel: reel,
                            isSelecting: model.isSelecting,
                            isSelected: model.selection.contains(reel.id),
                            onTap: { open(reel) },
                            onPin: { model.togglePin(id: reel.id, l10n: l10n) },
                            onSave: { save([reel]) },
                            onDelete: { model.delete(id: reel.id, l10n: l10n) }
                        )
                    }
                }
                .padding(.horizontal, 18)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.bottom, 24)
    }


    private var emptyState: some View {
        VStack(spacing: 16) {
            ReelBadge(size: 96, lineWidth: 4)

            Text(l10n.t("archive.empty.title"))
                .font(AppFont.display(19, weight: .semibold))
                .appTracking(2.2)
                .textCase(.uppercase)
                .foregroundStyle(AppColors.textSecondary)

            Text(l10n.t("archive.empty.body"))
                .font(AppFont.ui(12.5))
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(AppColors.textMuted)

            Button(l10n.t("archive.empty.cta")) {
                router.pop()
                router.isShowingSettings = true
            }
            .buttonStyle(MarqueeButtonStyle())
            .padding(.top, 2)

            Text(l10n.t("archive.limits", [
                "count": "\(ReplayStore.maxReelCount)",
                "size": ArchiveModel.sizeText(ReplayStore.maxTotalBytes),
            ]))
            .font(AppFont.ui(10.5))
            .lineSpacing(2)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(AppColors.textMuted.opacity(0.8))
            .padding(.top, 6)
        }
        .padding(.horizontal, 40)
        .frame(maxHeight: .infinity)
    }


    private var storageGroup: some View {
        @Bindable var settings = settings

        return SettingsGroup(title: l10n.t("archive.storage")) {
            SettingsRow(
                icon: "clock.arrow.circlepath",
                title: l10n.t("archive.retention"),
                placement: .below
            ) {
                SettingsSegment(
                    options: ReplayStore.Retention.allCases,
                    title: { l10n.t($0.labelKey) },
                    selection: Binding(
                        get: { settings.replayRetention },
                        set: { newValue in
                            settings.replayRetention = newValue
                            ReplayStore.enforcePolicy(retention: newValue)
                            model.load(l10n: l10n)
                        }
                    )
                )
            }

            SettingsDivider()

            SettingsRow(
                icon: "trash.slash",
                title: l10n.t("archive.wipeOnLaunch"),
                subtitle: l10n.t("archive.wipeOnLaunch.note")
            ) {
                MarqueeSwitch(
                    isOn: Binding(
                        get: { settings.replayWipeOnLaunch },
                        set: { newValue in
                            newValue ? Haptics.switchOn() : Haptics.switchOff()
                            settings.replayWipeOnLaunch = newValue
                        }
                    )
                )
            }

            SettingsDivider()

            SettingsRow(
                icon: "trash",
                title: l10n.t("archive.clear"),
                action: { isConfirmingClear = true }
            ) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.stateSkip)
                    .flipsForRightToLeftLayoutDirection(true)
            }
        }
    }


    private var selectionBar: some View {
        HStack(spacing: 10) {
            Text(l10n.t("archive.selected", ["count": "\(model.selection.count)"]))
                .font(AppFont.ui(11, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)

            Spacer(minLength: 0)

            Button {
                Haptics.secondaryButton()
                isConfirmingBulkDelete = true
            } label: {
                pillLabel(title: l10n.t("common.delete"), systemImage: "trash", isDestructive: true)
            }
            .buttonStyle(.plain)

            Button {
                Haptics.primaryButton()
                save(model.selectedReels())
            } label: {
                pillLabel(title: l10n.t("archive.save"), systemImage: "square.and.arrow.down", isPrimary: true)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 26)
        .background {
            LinearGradient(
                colors: [.clear, AppColors.bgFilmBlack.opacity(0.97)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func pillLabel(
        title: String,
        systemImage: String,
        isPrimary: Bool = false,
        isDestructive: Bool = false
    ) -> some View {
        let tint: Color = isPrimary
            ? AppColors.textOnAmber
            : (isDestructive ? AppColors.stateSkip : AppColors.textCream)

        return HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .font(AppFont.display(11.5, weight: .semibold))
                .appTracking(1.5)
                .textCase(.uppercase)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 15)
        .frame(height: 38)
        .background {
            Capsule()
                .fill(isPrimary ? AppColors.accentAmber : .clear)
                .overlay {
                    Capsule().strokeBorder(isPrimary ? .clear : tint.opacity(0.45), lineWidth: 1)
                }
        }
    }


    private func open(_ reel: ReplayReel) {
        guard !model.isSelecting else {
            Haptics.selection()
            model.toggleSelection(reel.id)
            return
        }
        Haptics.secondaryButton()


        let age = Calendar.current.dateComponents([.day], from: reel.createdAt, to: .now).day
        Analytics.replayArchivePlay(ageDays: max(age ?? 0, 0))
        router.push(.archivePlayer(reel.id))
    }

    private func save(_ reels: [ReplayReel]) {
        let urls = reels.map(\.videoURL)
        Task {
            switch await PhotoLibrary.save(urls) {
            case .saved:
                for _ in urls { Analytics.replaySave(source: .archive, slowMotionUsed: false) }
                Haptics.exportSucceeded()
                notice = l10n.t("archive.saved", count: urls.count)
                model.isSelecting = false
            case .denied:
                notice = l10n.t("archive.save.denied")
            case .failed:
                notice = l10n.t("archive.save.failed")
            }
        }
    }
}


struct ReelBadge: View {
    var size: CGFloat = 22
    var lineWidth: CGFloat = 2

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(AppColors.accentBrass.opacity(0.75), lineWidth: lineWidth)

            Circle()
                .strokeBorder(AppColors.accentBrass.opacity(0.55), lineWidth: lineWidth * 0.75)
                .frame(width: size * 0.23, height: size * 0.23)

            ForEach(0..<5, id: \.self) { index in
                let angle = Double(index) / 5 * 2 * .pi
                Circle()
                    .fill(AppColors.accentBrass.opacity(0.45))
                    .frame(width: size * 0.135, height: size * 0.135)
                    .offset(
                        x: cos(angle) * size * 0.3,
                        y: sin(angle) * size * 0.3
                    )
            }
        }
        .frame(width: size, height: size)
    }
}

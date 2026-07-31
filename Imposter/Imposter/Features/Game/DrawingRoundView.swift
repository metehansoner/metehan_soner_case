import SwiftUI
import Combine

struct DrawingCanvasView: View {
    @Bindable var live: LiveGame

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: 0xF7F1E3))

                CanvasDots()
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Canvas { context, _ in
                    for stroke in live.strokes {
                        draw(stroke, in: &context)
                    }
                    if let current = live.currentStroke {
                        draw(current, in: &context)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let p = value.location
                        guard p.x >= 0, p.y >= 0, p.x <= geo.size.width, p.y <= geo.size.height else { return }
                        if live.currentStroke == nil {
                            live.beginStroke(at: p)
                        } else {
                            live.appendStroke(point: p)
                        }
                    }
                    .onEnded { _ in
                        live.endStroke()
                    }
            )
            .disabled(live.isPaused || live.showDrawerOverlay)
        }
    }

    private func draw(_ stroke: DrawStroke, in context: inout GraphicsContext) {
        guard stroke.points.count > 1 else { return }
        var path = Path()
        path.move(to: stroke.points[0])
        for point in stroke.points.dropFirst() {
            path.addLine(to: point)
        }
        context.stroke(
            path,
            with: .color(stroke.color),
            style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round)
        )
    }
}

private struct CanvasDots: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 18
        var y: CGFloat = step
        while y < rect.height {
            var x: CGFloat = step
            while x < rect.width {
                path.addEllipse(in: CGRect(x: x - 0.7, y: y - 0.7, width: 1.4, height: 1.4))
                x += step
            }
            y += step
        }
        return path
    }
}

struct DrawingRoundView: View {
    @Bindable var live: LiveGame
    var onVote: () -> Void
    var onExit: () -> Void

    @Bindable private var l10n = LocalizationManager.shared
    @State private var showHowTo = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var selectedColorIndex = 0

    private var drawer: AssignedPlayer? { live.currentDrawer }
    private var isUrgent: Bool { live.remainingSeconds <= 10 && live.remainingSeconds > 0 }
    private var isEnded: Bool { live.remainingSeconds == 0 }

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 6)

                artistStrip
                    .padding(.top, 10)
                    .padding(.horizontal, 16)

                sketchBoard
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                toolDock
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                footerButtons
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
            }

            if live.showDrawerOverlay, let drawer {
                drawerStartOverlay(drawer)
            }

            if live.showExitConfirm {
                exitConfirmOverlay
            } else if live.isPaused && !live.showDrawerOverlay {
                PauseOverlay(
                    onResume: { live.isPaused = false },
                    onVote: {
                        live.isPaused = false
                        onVote()
                    }
                )
            }
        }
        .onReceive(timer) { _ in
            live.tick()
        }
        .sheet(isPresented: $showHowTo) {
            HowToPlaySheet(mode: live.mode)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                Haptics.light()
                live.showExitConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppColors.surfaceCardElevated))
            }
            .buttonStyle(.plain)

            VStack(spacing: 2) {
                Text(l10n.t("mode.drawing.title"))
                    .font(AppFont.display(17, weight: .black))
                    .foregroundStyle(AppColors.accentCyan)
                Text(l10n.t("drawing.tip"))
                    .font(AppFont.ui(11, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.85))
            }
            .frame(maxWidth: .infinity)

            timerChip

            Button {
                Haptics.light()
                showHowTo = true
            } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppColors.surfaceCardElevated))
            }
            .buttonStyle(.plain)
        }
    }

    private var timerChip: some View {
        HStack(spacing: 6) {
            Image(systemName: isEnded ? "alarm.fill" : "timer")
                .font(.system(size: 12, weight: .bold))
            Text(timeString)
                .font(AppFont.ui(14, weight: .bold))
                .monospacedDigit()
        }
        .foregroundStyle(isUrgent || isEnded ? AppColors.stateDanger : AppColors.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppColors.surfaceCardElevated)
                .overlay(
                    Capsule().stroke(
                        (isUrgent || isEnded ? AppColors.stateDanger : AppColors.accentCyan).opacity(0.45),
                        lineWidth: 1.5
                    )
                )
        )
    }

    private var artistStrip: some View {
        HStack(spacing: 8) {
            if let drawer {
                Image(drawer.avatarImageName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(drawer.accent))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1.5))

                Text(l10n.t("drawing.nowDrawing", ["name": drawer.name]))
                    .font(AppFont.display(16, weight: .black))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 8)

            HStack(spacing: 5) {
                ForEach(Array(live.players.enumerated()), id: \.element.id) { index, player in
                    Circle()
                        .fill(player.accent)
                        .frame(width: index == live.drawerIndex ? 12 : 8, height: index == live.drawerIndex ? 12 : 8)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(index == live.drawerIndex ? 0.9 : 0), lineWidth: 1.5)
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: live.drawerIndex)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surfaceCard.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppColors.accentCyan.opacity(0.22), lineWidth: 1)
                )
        )
    }

    private var sketchBoard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppColors.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppColors.accentCyan.opacity(0.75),
                                    AppColors.accentYellow.opacity(0.35),
                                    AppColors.accentCyan.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: AppColors.accentCyan.opacity(0.28), radius: 18, y: 8)

            DrawingCanvasView(live: live)
                .padding(10)

            VStack {
                HStack {
                    cornerMark
                    Spacer()
                    cornerMark
                }
                Spacer()
                HStack {
                    cornerMark
                    Spacer()
                    cornerMark
                }
            }
            .padding(18)
            .allowsHitTesting(false)
        }
    }

    private var cornerMark: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(AppColors.accentYellow.opacity(0.85))
            .frame(width: 14, height: 3)
    }

    private var toolDock: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(LiveGame.brushSizes, id: \.self) { size in
                    let selected = live.selectedLineWidth == size
                    Button {
                        Haptics.selection()
                        live.selectedLineWidth = size
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selected ? AppColors.accentCyan.opacity(0.22) : AppColors.surfaceCardElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(
                                            selected ? AppColors.accentCyan : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                            Circle()
                                .fill(AppColors.textPrimary)
                                .frame(width: size + 4, height: size + 4)
                        }
                        .frame(width: 44, height: 36)
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 6)

                toolIconButton(systemName: "arrow.uturn.backward", enabled: !live.strokes.isEmpty) {
                    live.undoStroke()
                }
                toolIconButton(systemName: "trash", enabled: !live.strokes.isEmpty) {
                    live.clearCanvas()
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(LiveGame.palette.enumerated()), id: \.offset) { index, color in
                        let selected = selectedColorIndex == index
                        Button {
                            Haptics.selection()
                            selectedColorIndex = index
                            live.selectedColor = color
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white, lineWidth: 2.5)
                                    .frame(width: 40, height: 40)
                                    .opacity(selected ? 1 : 0)

                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                                            .stroke(
                                                Color.white.opacity(color == .black ? 0.28 : 0.12),
                                                lineWidth: 1
                                            )
                                    )
                            }
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.surfaceCard.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func toolIconButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(enabled ? AppColors.textPrimary : AppColors.textSecondary.opacity(0.35))
                .frame(width: 40, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.surfaceCardElevated)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var footerButtons: some View {
        HStack(spacing: 10) {
            if live.isPaused || isEnded {
                Button {
                    Haptics.light()
                    live.isPaused = false
                    if isEnded {
                        live.remainingSeconds = live.roundDurationSeconds
                    }
                } label: {
                    Text(isEnded ? l10n.t("round.restartTimer") : l10n.t("round.resume"))
                }
                .buttonStyle(SecondaryCapsuleButtonStyle())

                Button {
                    Haptics.light()
                    onVote()
                } label: {
                    Text(l10n.t("round.vote"))
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button {
                    Haptics.light()
                    live.isPaused = true
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 58, height: 56)
                        .background(
                            Circle()
                                .fill(AppColors.btnSecondaryBg)
                                .overlay(
                                    Circle().stroke(AppColors.accentCyan.opacity(0.45), lineWidth: 1.5)
                                )
                        )
                }
                .buttonStyle(.plain)

                Button {
                    live.passToNextDrawer()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text(l10n.t("drawing.pass"))
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(live.showDrawerOverlay)
            }
        }
    }

    private func drawerStartOverlay(_ drawer: AssignedPlayer) -> some View {
        ZStack {
            drawer.accent.ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                Image(drawer.avatarImageName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .shadow(color: .black.opacity(0.28), radius: 18, y: 10)

                Text(l10n.t("drawing.starting", ["name": drawer.name]))
                    .font(AppFont.display(28, weight: .black))
                    .foregroundStyle(overlayText(for: drawer))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Text(l10n.t("drawing.instruction"))
                    .font(AppFont.ui(15, weight: .bold))
                    .foregroundStyle(overlayText(for: drawer).opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)

                Spacer()

                Button {
                    live.dismissDrawerOverlay()
                } label: {
                    Text(l10n.t("common.gotIt"))
                }
                .buttonStyle(DarkCapsuleStyle(textOnLight: needsDarkText(for: drawer)))
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .transition(.opacity)
    }

    private func needsDarkText(for player: AssignedPlayer) -> Bool {
        [4, 5, 9, 12, 14].contains(player.avatarIndex)
    }

    private func overlayText(for player: AssignedPlayer) -> Color {
        needsDarkText(for: player) ? AppColors.textOnLight : .white
    }

    private var exitConfirmOverlay: some View {
        ExitGameConfirmOverlay(
            onCancel: { live.showExitConfirm = false },
            onConfirm: {
                live.showExitConfirm = false
                onExit()
            }
        )
    }

    private var timeString: String {
        let m = live.remainingSeconds / 60
        let s = live.remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

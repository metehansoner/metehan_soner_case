import SwiftUI
import Combine

struct DrawingCanvasView: View {
    @Bindable var live: LiveGame

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppColors.surfaceCanvas)

                Canvas { context, _ in
                    for stroke in live.strokes {
                        draw(stroke, in: &context)
                    }
                    if let current = live.currentStroke {
                        draw(current, in: &context)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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

struct DrawingRoundView: View {
    @Bindable var live: LiveGame
    var onVote: () -> Void
    var onExit: () -> Void

    @Bindable private var l10n = LocalizationManager.shared
    @State private var showHowTo = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var selectedColorIndex = 0

    var body: some View {
        ZStack {
            OceanBackground()

            VStack(spacing: 12) {
                header

                DrawingCanvasView(live: live)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 320)
                    .padding(.horizontal, 16)

                toolbar
                    .padding(.horizontal, 12)

                footerButtons
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }

            if live.showDrawerOverlay, let drawer = live.currentDrawer {
                drawerStartOverlay(drawer)
            }

            if live.isPaused && live.remainingSeconds > 0 && !live.showDrawerOverlay {
                pauseOverlay
            }

            if live.showExitConfirm {
                exitConfirmOverlay
            }
        }
        .onReceive(timer) { _ in
            live.tick()
        }
        .sheet(isPresented: $showHowTo) {
            HowToPlaySheet()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button {
                Haptics.light()
                live.showExitConfirm = true
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 36, height: 36)
            }

            Text(l10n.t("app.name"))
                .font(AppFont.display(20, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(AppColors.accentYellow)
                    .frame(width: 10, height: 10)
                Text(timeString)
                    .font(AppFont.ui(16, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(AppColors.surfaceCardElevated))

            Button {
                Haptics.light()
                showHowTo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button {
                live.undoStroke()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 36, height: 36)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(LiveGame.palette.enumerated()), id: \.offset) { index, color in
                        Button {
                            Haptics.selection()
                            selectedColorIndex = index
                            live.selectedColor = color
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedColorIndex == index ? Color.white : .clear,
                                            lineWidth: 2.5
                                        )
                                )
                        }
                    }
                }
            }

            Button {
                live.clearCanvas()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 36, height: 36)
            }
        }
    }

    private var footerButtons: some View {
        HStack(spacing: 10) {
            if live.isPaused || live.remainingSeconds == 0 {
                Button {
                    Haptics.light()
                    live.isPaused = false
                    if live.remainingSeconds == 0 {
                        live.remainingSeconds = live.roundDurationSeconds
                    }
                } label: {
                    Text(l10n.t("round.resume"))
                }
                .buttonStyle(PrimaryButtonStyle())

                Button(action: onVote) {
                    Text(l10n.t("round.vote"))
                }
                .buttonStyle(SecondaryCapsuleButtonStyle())
            } else {
                Button {
                    Haptics.light()
                    live.isPaused = true
                } label: {
                    Text(l10n.t("round.pause"))
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    live.passToNextDrawer()
                } label: {
                    Text(l10n.t("common.continue"))
                }
                .buttonStyle(SecondaryCapsuleButtonStyle())
                .disabled(live.showDrawerOverlay)
            }
        }
    }

    private func drawerStartOverlay(_ drawer: AssignedPlayer) -> some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.accentCyan)

                Text(l10n.t("drawing.starting", ["name": drawer.name]))
                    .font(AppFont.display(24, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(l10n.t("drawing.instruction"))
                    .font(AppFont.ui(14))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                Button {
                    live.dismissDrawerOverlay()
                } label: {
                    Text(l10n.t("common.gotIt"))
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppColors.surfaceCard)
            )
            .padding(.horizontal, 28)
        }
    }

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 10) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
                Text(l10n.t("round.paused"))
                    .font(AppFont.display(28, weight: .bold))
                    .foregroundStyle(.white)
                Text(l10n.t("round.tapToContinue"))
                    .font(AppFont.ui(15))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .onTapGesture {
                Haptics.light()
                live.isPaused = false
            }
        }
    }

    private var exitConfirmOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(l10n.t("drawing.exitTitle"))
                    .font(AppFont.display(24, weight: .bold))
                    .foregroundStyle(.white)
                Text(l10n.t("drawing.exitBody"))
                    .font(AppFont.ui(14))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button {
                        live.showExitConfirm = false
                    } label: {
                        Text(l10n.t("common.cancel"))
                            .font(AppFont.ui(16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1.5)
                            )
                    }

                    Button {
                        live.showExitConfirm = false
                        onExit()
                    } label: {
                        Text(l10n.t("drawing.exitConfirm"))
                            .font(AppFont.ui(16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(AppColors.stateDanger))
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppColors.surfaceCard)
            )
            .padding(.horizontal, 28)
        }
    }

    private var timeString: String {
        let m = live.remainingSeconds / 60
        let s = live.remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

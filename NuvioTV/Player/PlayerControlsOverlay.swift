import SwiftUI

/// Bottom-anchored playback controls modeled on NuvioTV's player overlay:
/// title block, accent progress bar, icon button row with the time readout
/// on the right, all over black gradients.
struct PlayerControlsOverlay: View {
    @EnvironmentObject private var theme: ThemeManager
    @ObservedObject var viewModel: PlayerViewModel
    @FocusState private var focusedControl: Control?
    /// Scopes the button row so entering it from the timeline lands on the
    /// preferred default (play/pause) instead of the geometrically-nearest
    /// button — otherwise pressing down off the full-width bar jumps to
    /// whichever icon happens to sit below the thumb.
    @Namespace private var buttonScope

    enum Control: Hashable {
        case timeline
        case playPause
        case nextEpisode
        case subtitles
        case audio
        case sources
        case episodes
        case speed
        case aspect
        case engine
    }

    var body: some View {
        ZStack {
            gradients
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                titleBlock
                    .padding(.bottom, NuvioSpacing.md)
                TimelineBar(
                    viewModel: viewModel,
                    clock: viewModel.clock,
                    isFocused: focusedControl == .timeline,
                    onDown: { focusedControl = .playPause }
                )
                .focused($focusedControl, equals: .timeline)
                .padding(.bottom, NuvioSpacing.md)
                buttonRow
                    .focusScope(buttonScope)
            }
            .padding(.horizontal, NuvioSpacing.huge)
            .padding(.bottom, NuvioSpacing.xxl)
        }
        .onAppear { focusedControl = .playPause }
        // Any focus movement inside the controls counts as activity — the
        // idle timer only runs down while the remote is truly untouched.
        .onChange(of: focusedControl) { oldValue, newValue in
            viewModel.restartHideTimer()
            // Guarantee: coming DOWN off the full-width timeline always lands on
            // Play/Pause. The focus engine occasionally still does its own
            // geometry move to the nearest icon under the thumb before
            // prefersDefaultFocus/onDown apply — snap it back.
            if oldValue == .timeline, let newValue, newValue != .playPause {
                focusedControl = .playPause
            }
        }
    }

    private var gradients: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [.black.opacity(0.7), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 170)
            Spacer()
            LinearGradient(
                colors: [.clear, .black.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 320)
        }
        .ignoresSafeArea()
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(viewModel.displayTitle)
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
            if let episodeLine = viewModel.episodeLine {
                Text(episodeLine)
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }
            HStack(spacing: NuvioSpacing.md) {
                if let year = viewModel.meta.year {
                    Text(year)
                        .font(.system(size: 21))
                        .foregroundStyle(.white.opacity(0.68))
                }
                if !viewModel.isPlaying, let via = viewModel.viaLine {
                    Text(via)
                        .font(.system(size: 21))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(1)
                }
            }
        }
    }

    private var buttonRow: some View {
        HStack(spacing: NuvioSpacing.sm) {
            ControlIconButton(
                systemName: viewModel.isPlaying ? "pause.fill" : "play.fill",
                label: viewModel.isPlaying ? "Pause" : "Play"
            ) {
                viewModel.togglePlayPause()
                viewModel.restartHideTimer()
            }
            .focused($focusedControl, equals: .playPause)
            .prefersDefaultFocus(in: buttonScope)

            if viewModel.nextEpisode != nil {
                ControlIconButton(systemName: "forward.end.fill", label: "Next Episode") {
                    if let next = viewModel.nextEpisode {
                        viewModel.play(episode: next)
                    }
                }
                .focused($focusedControl, equals: .nextEpisode)
            }

            if !viewModel.subtitleOptions.isEmpty {
                ControlIconButton(systemName: "captions.bubble", label: "Subtitles") {
                    viewModel.overlay = .subtitles
                }
                .focused($focusedControl, equals: .subtitles)
            }

            if !viewModel.audioOptions.isEmpty {
                ControlIconButton(systemName: "waveform", label: "Audio") {
                    viewModel.overlay = .audio
                }
                .focused($focusedControl, equals: .audio)
            }

            ControlIconButton(systemName: "arrow.left.arrow.right", label: "Sources") {
                viewModel.overlay = .sources
            }
            .focused($focusedControl, equals: .sources)

            if viewModel.currentVideo != nil {
                ControlIconButton(systemName: "list.bullet", label: "Episodes") {
                    viewModel.overlay = .episodes
                }
                .focused($focusedControl, equals: .episodes)
            }

            ControlIconButton(systemName: "speedometer", label: "Speed") {
                viewModel.overlay = .speed
            }
            .focused($focusedControl, equals: .speed)

            ControlIconButton(systemName: "aspectratio", label: "Aspect") {
                viewModel.cycleAspect()
                viewModel.restartHideTimer()
            }
            .focused($focusedControl, equals: .aspect)

            ControlIconButton(systemName: "cpu", label: "Engine") {
                viewModel.overlay = .engine
            }
            .focused($focusedControl, equals: .engine)

            Spacer()

            timeReadout
        }
    }

    private var timeReadout: some View {
        TimeReadout(viewModel: viewModel, clock: viewModel.clock)
    }
}

/// Elapsed (+pending skip) / total readout. Observes the clock so it ticks
/// without dragging the rest of the overlay into re-render.
private struct TimeReadout: View {
    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var clock: PlaybackClock

    var body: some View {
        HStack(spacing: 6) {
            Text(TimeFormat.clock(clock.position + viewModel.pendingSeekDelta))
                .font(.system(size: 25, weight: .semibold).monospacedDigit())
                .foregroundStyle(.white)
            Text("/ \(TimeFormat.clock(clock.duration))")
                .font(.system(size: 25, weight: .medium).monospacedDigit())
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

/// A round control with its name captioned underneath while focused, so every
/// button is self-explanatory without hunting. The caption slot is always
/// reserved (opacity swap) so the row never jumps.
struct ControlIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    init(systemName: String, label: String, action: @escaping () -> Void) {
        self.systemName = systemName
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            IconCircle(systemName: systemName, label: label)
        }
        .buttonStyle(PlainCardButtonStyle())
        .accessibilityLabel(label)
    }
}

private struct IconCircle: View {
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.isFocused) private var isFocused

    let systemName: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemName)
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(isFocused ? theme.palette.onSecondary : .white)
                .frame(width: 62, height: 62)
                .background(
                    Circle().fill(isFocused ? theme.palette.secondary : .white.opacity(0.12))
                )
                .overlay(
                    Circle().strokeBorder(isFocused ? theme.palette.focusRing.opacity(0.9) : .clear, lineWidth: 2)
                )
                .scaleEffect(isFocused ? 1.1 : 1)

            Text(label)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .opacity(isFocused ? 1 : 0)
                .lineLimit(1)
                .fixedSize()
        }
        .animation(.spring(response: 0.24, dampingFraction: 0.85), value: isFocused)
    }
}

/// The Nuvio progress bar: rounded track that thickens when focused, accent
/// buffered fill under an accent played fill. D-pad left/right nudge-seeks
/// while focused (with debounce commit), exactly like the Android app.
struct TimelineBar: View {
    @EnvironmentObject private var theme: ThemeManager
    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var clock: PlaybackClock
    let isFocused: Bool
    let onDown: () -> Void

    var body: some View {
        let duration = max(clock.duration, 1)
        let previewPosition = min(max(clock.position + viewModel.pendingSeekDelta, 0), duration)
        let elapsed = previewPosition
        let remaining = max(duration - previewPosition, 0)

        VStack(spacing: NuvioSpacing.sm) {
            ProgressTrack(
                played: previewPosition / duration,
                buffered: min(clock.buffered / duration, 1),
                height: 10,
                showThumb: true,
                emphasized: isFocused
            )
            HStack(alignment: .firstTextBaseline) {
                // LEFT: elapsed + (only when the bar is HIGHLIGHTED) the
                // wall-clock time you started.
                VStack(alignment: .leading, spacing: 1) {
                    Text(TimeFormat.clock(elapsed))
                        .font(.system(size: 21, weight: .semibold).monospacedDigit())
                        .foregroundStyle(.white.opacity(isFocused ? 1 : 0.8))
                    if isFocused {
                        Text("Started \(WatchClock.started(position: clock.position))")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
                if viewModel.pendingSeekDelta != 0 {
                    Text(TimeFormat.signedDelta(viewModel.pendingSeekDelta))
                        .font(.system(size: 21, weight: .bold).monospacedDigit())
                        .foregroundStyle(theme.palette.secondary)
                }
                Spacer()
                // RIGHT: remaining + (only when highlighted) the wall-clock
                // time you'll finish.
                VStack(alignment: .trailing, spacing: 1) {
                    Text("-\(TimeFormat.clock(remaining))")
                        .font(.system(size: 21, weight: .medium).monospacedDigit())
                        .foregroundStyle(.white.opacity(isFocused ? 0.7 : 0.6))
                    if isFocused {
                        Text("Ends \(WatchClock.ends(position: clock.position, duration: duration))")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
        }
        .focusable()
        // Click the focused timeline → drop into scrub to fine-tune the time.
        .onTapGesture { viewModel.beginScrub() }
        .onMoveCommand { direction in
            // onMoveCommand consumes every direction, so down must be routed
            // to the button row by hand or focus gets stuck on the timeline.
            switch direction {
            case .left: viewModel.nudgeSeek(-Double(viewModel.settings.skipSeconds))
            case .right: viewModel.nudgeSeek(Double(viewModel.settings.skipSeconds))
            case .down: onDown()
            // Up does NOT hide the controls — only the auto-timer and Back ever
            // hide the menu. It just restarts the idle timer (stay visible).
            case .up: viewModel.restartHideTimer()
            @unknown default: break
            }
        }
        .animation(.easeOut(duration: 0.18), value: isFocused)
    }
}

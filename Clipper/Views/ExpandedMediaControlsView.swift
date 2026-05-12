import SwiftUI
import AppKit

struct ExpandedMediaControlsView: View {
    @EnvironmentObject var nowPlayingState: NowPlayingState

    @State private var sliderValue: Double = 0
    @State private var isDragging = false
    @State private var lastDragged: Date = .distantPast
    @State private var displayTitle: String = ""
    @State private var displayArtist: String = ""

    private var item: NowPlayingItem? { nowPlayingState.item }

    var body: some View {
        if let item {
            VStack(spacing: 0) {
                headerRow(item: item)
                progressBar(item: item)
                    .padding(.top, 6)
                transportRow
                    .padding(.top, 4)
            }
            .padding(.horizontal, 48)
            .padding(.top, 20)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear {
                sliderValue = item.estimatedElapsedTime
                displayTitle = item.title
                displayArtist = item.artist
            }
            .onChange(of: item.title) { _, newTitle in
                sliderValue = item.elapsedTime
                displayTitle = newTitle
            }
            .onChange(of: item.artist) { _, newArtist in
                displayArtist = newArtist
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "music.note.slash")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.gray)
                Text("Nothing Playing")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Header

    private var tintColor: Color {
        Color(nsColor: nowPlayingState.avgColor).ensureMinimumBrightness()
    }

    private func headerRow(item: NowPlayingItem) -> some View {
        GeometryReader { geo in
            let artSize: CGFloat = 50
            let artSpacing: CGFloat = 10
            let vizWidth: CGFloat = 13
            let vizSpacing: CGFloat = 8
            // 4 items → 3 gaps of artSpacing; subtract all fixed widths + all spacings
            let textWidth = max(0, geo.size.width - artSize - 3 * artSpacing - vizWidth - vizSpacing)

            HStack(alignment: .center, spacing: artSpacing) {
                artworkView(item: item)
                    .frame(width: artSize, height: artSize)

                VStack(alignment: .leading, spacing: 1) {
                    MarqueeText(
                        $displayTitle,
                        font: .system(size: 12, weight: .semibold),
                        nsFont: .subheadline,
                        textColor: .white,
                        frameWidth: textWidth
                    )
                    MarqueeText(
                        $displayArtist,
                        font: .system(size: 10, weight: .regular),
                        nsFont: .caption1,
                        textColor: .gray,
                        frameWidth: textWidth
                    )
                }
                .frame(width: textWidth, alignment: .leading)

                Spacer(minLength: vizSpacing)

                MusicVisualizerView(isPlaying: item.isPlaying, color: tintColor)
                    .frame(width: vizWidth, height: 16)
            }
        }
        .frame(height: 50)
    }

    // MARK: - Album Art

    private func artworkView(item: NowPlayingItem) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                // Glow: blurred rotated copy of the artwork, expanded beyond art frame
                if let artwork = item.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .scaleEffect(1.8)
                        .blur(radius: 20)
                        .opacity(item.isPlaying ? 0.55 : 0)
                        .animation(.easeInOut(duration: 0.3), value: item.isPlaying)
                        .allowsHitTesting(false)
                }

                artworkImage(item: item)
            }

            // App icon badge — bottom-right corner, partially outside the art frame
            if let icon = playerAppIcon(for: item.appName) {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
                    .offset(x: 7, y: 7)
                    .transition(.scale.combined(with: .opacity).animation(.bouncy.delay(0.25)))
            }
        }
    }

    private func playerAppIcon(for bundleID: String) -> NSImage? {
        guard !bundleID.isEmpty else { return nil }

        // Running app icon — sandbox-safe, music player is always running when playing
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first,
           let icon = app.icon {
            return icon
        }

        // Fallback: workspace lookup
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }

        return nil
    }

    private func artworkImage(item: NowPlayingItem) -> some View {
        ZStack {
            Color.black
            if let artwork = item.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .albumArtFlip(angle: nowPlayingState.flipAngle)
        .opacity(item.isPlaying ? 1.0 : 0.4)
        .scaleEffect(item.isPlaying ? 1.0 : 0.85)
        .animation(.easeInOut(duration: 0.2), value: item.isPlaying)
    }

    // MARK: - Progress Bar

    @ViewBuilder
    private func progressBar(item: NowPlayingItem) -> some View {
        if item.duration > 0 {
            TimelineView(
                .animation(
                    minimumInterval: 1.0,
                    paused: !item.isPlaying || item.playbackRate <= 0
                )
            ) { timeline in
                InlineProgressBar(
                    sliderValue: $sliderValue,
                    isDragging: $isDragging,
                    lastDragged: $lastDragged,
                    duration: item.duration,
                    elapsedTime: item.elapsedTime,
                    timestampDate: item.lastUpdated,
                    playbackRate: item.playbackRate,
                    isPlaying: item.isPlaying,
                    currentDate: timeline.date,
                    tintColor: tintColor,
                    onSeek: { nowPlayingState.seek(to: $0) }
                )
            }
        }
    }

    // MARK: - Transport Controls

    private var transportRow: some View {
        HStack(spacing: 0) {
            // Shuffle
            SquircleButton(
                systemImage: "shuffle",
                fontSize: 15,
                frameSize: CGSize(width: 40, height: 40),
                cornerRadius: 16,
                foregroundColor: item?.isShuffled == true ? tintColor : .white.opacity(0.6)
            ) { nowPlayingState.toggleShuffle() }

            Spacer(minLength: 0)

            // Previous
            SquircleButton(
                systemImage: "backward.fill",
                fontSize: 18,
                frameSize: CGSize(width: 40, height: 40),
                cornerRadius: 16,
                foregroundColor: .white.opacity(0.85),
                pressEffect: .nudge(-8)
            ) { nowPlayingState.previousTrack() }

            Spacer(minLength: 0)

            // Play / Pause
            SquircleButton(
                systemImage: item?.isPlaying == true ? "pause.fill" : "play.fill",
                fontSize: 28,
                frameSize: CGSize(width: 60, height: 60),
                cornerRadius: 24,
                foregroundColor: .white,
                symbolEffect: .replace
            ) { nowPlayingState.playPause() }

            Spacer(minLength: 0)

            // Next
            SquircleButton(
                systemImage: "forward.fill",
                fontSize: 18,
                frameSize: CGSize(width: 40, height: 40),
                cornerRadius: 16,
                foregroundColor: .white.opacity(0.85),
                pressEffect: .nudge(8)
            ) { nowPlayingState.nextTrack() }

            Spacer(minLength: 0)

            // Output device
            SquircleButton(
                systemImage: "laptopcomputer",
                fontSize: 15,
                frameSize: CGSize(width: 40, height: 40),
                cornerRadius: 16,
                foregroundColor: .white.opacity(0.5)
            ) {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.sound")!)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Inline Progress Bar

private struct InlineProgressBar: View {
    @Binding var sliderValue: Double
    @Binding var isDragging: Bool
    @Binding var lastDragged: Date
    let duration: Double
    let elapsedTime: Double
    let timestampDate: Date
    let playbackRate: Double
    let isPlaying: Bool
    let currentDate: Date
    var tintColor: Color = .gray
    var onSeek: (Double) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(timeString(from: sliderValue))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(tintColor)
                .frame(width: 42, alignment: .leading)

            ProgressSlider(
                value: $sliderValue,
                range: 0...duration,
                isDragging: $isDragging,
                lastDragged: $lastDragged,
                onSeek: onSeek
            )
            .frame(height: max(7, 11))
            .frame(maxWidth: .infinity)
            .animation(
                !isDragging && isPlaying ? .linear(duration: 1.0) : nil,
                value: sliderValue
            )

            Text(remainingString)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(tintColor)
                .frame(width: 48, alignment: .trailing)
        }
        .onChange(of: currentDate) { _, newDate in
            guard !isDragging, timestampDate.timeIntervalSince(lastDragged) > -1 else { return }
            let estimated = elapsedTime + newDate.timeIntervalSince(timestampDate) * playbackRate
            sliderValue = min(max(estimated, 0), duration)
        }
        .onChange(of: isPlaying) { _, playing in
            if !playing { sliderValue = elapsedTime }
        }
    }

    private var remainingString: String {
        "-" + timeString(from: max(duration - sliderValue, 0))
    }

    private func timeString(from seconds: Double) -> String {
        let t = Int(max(seconds, 0))
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}

// MARK: - Progress Slider (mirrors Atoll's CustomSlider)

private struct ProgressSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    @Binding var isDragging: Bool
    @Binding var lastDragged: Date
    var onSeek: (Double) -> Void
    var restingTrackHeight: CGFloat = 7
    var draggingTrackHeight: CGFloat = 11

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let trackHeight = isDragging ? draggingTrackHeight : restingTrackHeight
            let span = range.upperBound - range.lowerBound
            let progress = span == 0 ? 0 : (value - range.lowerBound) / span
            let filled = min(max(progress, 0), 1) * width

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: trackHeight)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: filled, height: trackHeight)
            }
            .cornerRadius(trackHeight / 2)
            .frame(height: max(restingTrackHeight, draggingTrackHeight))
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        withAnimation { isDragging = true }
                        let newValue = range.lowerBound + Double(gesture.location.x / width) * span
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        onSeek(value)
                        isDragging = false
                        lastDragged = Date()
                    }
            )
            .animation(.bouncy.speed(1.4), value: isDragging)
        }
    }
}

// MARK: - Squircle Button (mirrors Atoll's MinimalisticSquircircleButton)

struct SquircleButton: View {
    let systemImage: String
    let fontSize: CGFloat
    let frameSize: CGSize
    let cornerRadius: CGFloat
    let foregroundColor: Color
    var pressEffect: PressEffect = .none
    var symbolEffect: SymbolEffect = .none
    let action: () -> Void

    @State private var isHovering = false
    @State private var pressOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var wiggleToken: Int = 0

    var body: some View {
        Button {
            triggerPressEffect()
            action()
        } label: {
            iconView
                .frame(width: frameSize.width, height: frameSize.height)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(isHovering ? Color.white.opacity(0.18) : .clear)
                )
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .offset(x: pressOffset)
        .rotationEffect(.degrees(rotationAngle))
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.18)) { isHovering = hovering }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        let base = Image(systemName: systemImage)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(foregroundColor)

        switch symbolEffect {
        case .none:
            base
        case .replace:
            if #available(macOS 14.0, *) {
                base.contentTransition(.symbolEffect(.replace))
            } else {
                base
            }
        }
    }

    private func triggerPressEffect() {
        switch pressEffect {
        case .none: break

        case .nudge(let amount):
            withAnimation(.spring(response: 0.16, dampingFraction: 0.72)) {
                pressOffset = amount
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
                    pressOffset = 0
                }
            }

        case .wiggle(let direction):
            guard #available(macOS 14.0, *) else { return }
            wiggleToken += 1
            let angle: Double = direction == .clockwise ? 11 : -11
            withAnimation(.spring(response: 0.18, dampingFraction: 0.52)) {
                rotationAngle = angle
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                    rotationAngle = 0
                }
            }
        }
    }

    enum PressEffect {
        case none
        case nudge(CGFloat)
        case wiggle(WiggleDirection)
    }

    enum WiggleDirection {
        case clockwise
        case counterClockwise
    }

    enum SymbolEffect {
        case none
        case replace
    }
}

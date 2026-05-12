import SwiftUI
import AppKit

struct ExpandedMediaControlsView: View {
    @EnvironmentObject var nowPlayingState: NowPlayingState

    @State private var sliderValue: Double = 0
    @State private var isDragging = false
    @State private var lastDragged: Date = .distantPast

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
            .padding(.horizontal, 38)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear {
                sliderValue = item.estimatedElapsedTime
            }
            .onChange(of: item.title) { _, _ in
                sliderValue = item.elapsedTime
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

    private func headerRow(item: NowPlayingItem) -> some View {
        HStack(alignment: .center, spacing: 10) {
            artworkBlock(item: item)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(item.artist)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 50)
    }

    // MARK: - Album Art

    private func artworkBlock(item: NowPlayingItem) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.20, green: 0.20, blue: 0.24), Color(red: 0.10, green: 0.10, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if let nsImage = item.artwork {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                    onSeek: { nowPlayingState.seek(to: $0) }
                )
            }
        }
    }

    // MARK: - Transport Controls

    private var transportRow: some View {
        HStack(spacing: 16) {
            Spacer(minLength: 0)
            SquircleButton(
                systemImage: "backward.fill",
                fontSize: 18,
                frameSize: CGSize(width: 40, height: 40),
                cornerRadius: 16,
                foregroundColor: .white.opacity(0.85),
                pressEffect: .nudge(-8)
            ) {
                nowPlayingState.previousTrack()
            }
            SquircleButton(
                systemImage: item?.isPlaying == true ? "pause.fill" : "play.fill",
                fontSize: 28,
                frameSize: CGSize(width: 60, height: 60),
                cornerRadius: 24,
                foregroundColor: .white,
                symbolEffect: .replace
            ) {
                nowPlayingState.playPause()
            }
            SquircleButton(
                systemImage: "forward.fill",
                fontSize: 18,
                frameSize: CGSize(width: 40, height: 40),
                cornerRadius: 16,
                foregroundColor: .white.opacity(0.85),
                pressEffect: .nudge(8)
            ) {
                nowPlayingState.nextTrack()
            }
            Spacer(minLength: 0)
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
    var onSeek: (Double) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(timeString(from: sliderValue))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.gray)
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
                .foregroundStyle(.gray)
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

// MARK: - Progress Slider (Atoll's CustomSlider)

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

// MARK: - Squircle Button (Atoll's MinimalisticSquircircleButton)

private struct SquircleButton: View {
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
        }
    }

    enum PressEffect {
        case none
        case nudge(CGFloat)
    }

    enum SymbolEffect {
        case none
        case replace
    }
}

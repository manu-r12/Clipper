import SwiftUI
import AppKit

struct ExpandedMediaControlsView: View {
    @EnvironmentObject var nowPlayingState: NowPlayingState

    @State private var isDragging = false
    @State private var scrubTime: Double = 0

    private var item: NowPlayingItem? { nowPlayingState.item }

    var body: some View {
        if item != nil {
            // Top-anchored stack matching Atoll's minimalistic layout:
            //   [albumArt] [title / artist]        ← header row (52pt tall)
            //   [progress bar ─────────────]       ← full width, inline times
            //   [  ←   ▶   →  ]                   ← controls, centered
            VStack(spacing: 0) {
                headerRow
                progressBar
                    .padding(.top, 8)
                transportRow
                    .padding(.top, 6)
            }
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            Text("Currently no media playing")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 10) {
            artworkBlock
            VStack(alignment: .leading, spacing: 1) {
                Text(item?.title ?? "")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(item?.artist ?? "")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 52)
    }

    // MARK: - Album Art

    private var artworkBlock: some View {
        ZStack {
            artworkBackground
            artworkImage
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 0.6)
        }
    }

    @ViewBuilder
    private var artworkImage: some View {
        if let nsImage = item?.artwork {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "music.note")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var artworkBackground: some View {
        LinearGradient(
            colors: [Color(red: 0.20, green: 0.20, blue: 0.24), Color(red: 0.10, green: 0.10, blue: 0.12)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Progress Bar (full-width, inline time labels)

    @ViewBuilder
    private var progressBar: some View {
        if let item, item.duration > 0 {
            TimelineView(.animation(minimumInterval: 0.5)) { _ in
                // Inline layout: [elapsed] [track] [duration]
                HStack(spacing: 8) {
                    let elapsed = isDragging ? scrubTime : item.estimatedElapsedTime
                    Text(formatTime(elapsed))
                        .frame(width: 38, alignment: .leading)

                    GeometryReader { geo in
                        let progress = min(max(elapsed / item.duration, 0), 1)
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.15)).frame(height: isDragging ? 5 : 4)
                            Capsule()
                                .fill(Color.white.opacity(isDragging ? 1.0 : 0.8))
                                .frame(width: geo.size.width * progress, height: isDragging ? 5 : 4)
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = true
                                    scrubTime = min(max(value.location.x / geo.size.width, 0), 1) * item.duration
                                }
                                .onEnded { _ in
                                    nowPlayingState.seek(to: scrubTime)
                                    isDragging = false
                                }
                        )
                    }
                    .frame(height: 16)

                    Text(formatTime(item.duration))
                        .frame(width: 38, alignment: .trailing)
                }
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.40))
            }
        }
    }

    private func formatTime(_ s: Double) -> String {
        let t = Int(max(s, 0))
        return String(format: "%d:%02d", t / 60, t % 60)
    }

    // MARK: - Transport Controls

    private var transportRow: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            MediaButton(systemImage: "backward.fill", size: 40, iconSize: 16, isPrimary: false) {
                nowPlayingState.previousTrack()
            }
            Spacer(minLength: 0)
            MediaButton(
                systemImage: item?.isPlaying == true ? "pause.fill" : "play.fill",
                size: 52,
                iconSize: 22,
                isPrimary: true
            ) {
                nowPlayingState.playPause()
            }
            Spacer(minLength: 0)
            MediaButton(systemImage: "forward.fill", size: 40, iconSize: 16, isPrimary: false) {
                nowPlayingState.nextTrack()
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - MediaButton (squircle, matches Atoll's MinimalisticSquircircleButton)

private struct MediaButton: View {
    let systemImage: String
    let size: CGFloat
    let iconSize: CGFloat
    let isPrimary: Bool
    let action: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(isPrimary ? .black : .white)
                .offset(x: systemImage == "play.fill" ? 1 : 0)
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: size * 0.38, style: .continuous)
                        .fill(isPrimary
                              ? AnyShapeStyle(Color.white)
                              : AnyShapeStyle(Color.white.opacity(isHovering ? 0.14 : 0.08)))
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.93 : 1.0)
        .animation(.easeOut(duration: 0.10), value: isPressed)
        .onHover { isHovering = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

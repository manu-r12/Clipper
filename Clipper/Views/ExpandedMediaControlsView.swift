import SwiftUI
import AppKit

struct ExpandedMediaControlsView: View {
    @EnvironmentObject var nowPlayingState: NowPlayingState

    var body: some View {
        HStack(spacing: 16) {
            artworkBlock

            VStack(alignment: .leading, spacing: 10) {
                titleBlock
                transportRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var item: NowPlayingItem? {
        nowPlayingState.item
    }

    private var titleText: String {
        let text = item?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? "Nothing Playing" : text
    }

    private var subtitleText: String {
        guard let item else { return "No active media session" }

        let artist = item.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let app = item.appName.trimmingCharacters(in: .whitespacesAndNewlines)

        if !artist.isEmpty && !app.isEmpty {
            return "\(artist) • \(app)"
        }

        if !artist.isEmpty {
            return artist
        }

        if !app.isEmpty {
            return app
        }

        return "No active media session"
    }

    private var artworkBlock: some View {
        ZStack {
            artworkBackground

            artworkImage
        }
        .frame(width: 68, height: 68)
        .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 0.7)
        }
        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
    }

    @ViewBuilder
    private var artworkImage: some View {
        if let nsImage = item?.artwork {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "music.note")
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
        }
    }

    private var artworkBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.22, green: 0.22, blue: 0.26),
                Color(red: 0.10, green: 0.10, blue: 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titleText)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)

            Text(subtitleText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.60))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private var transportRow: some View {
        HStack(spacing: 10) {
            IslandActionButton(
                systemImage: "backward.fill",
                role: .secondary,
                size: 36
            ) {
                nowPlayingState.previousTrack()
            }

            IslandActionButton(
                systemImage: item?.isPlaying == true ? "pause.fill" : "play.fill",
                role: .primary,
                size: 44
            ) {
                nowPlayingState.playPause()
            }

            IslandActionButton(
                systemImage: "forward.fill",
                role: .secondary,
                size: 36
            ) {
                nowPlayingState.nextTrack()
            }
        }
        .padding(.top, 2)
    }
}

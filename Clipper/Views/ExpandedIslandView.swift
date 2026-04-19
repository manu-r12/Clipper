//
//  ExpandedIslandView.swift
//  Clipper
//
//  Created by Manu on 2026-04-18.
//


import SwiftUI

struct ExpandedIslandView: View {
    @EnvironmentObject var nowPlayingState: NowPlayingState
    let isPinned: Bool

    var body: some View {
        HStack(spacing: 14) {
            artworkBlock
            textBlock
            controlsBlock
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var item: NowPlayingItem? {
        nowPlayingState.item
    }

    private var artworkBlock: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.24, green: 0.24, blue: 0.28),
                            Color(red: 0.12, green: 0.12, blue: 0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "music.note")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(width: 56, height: 56)
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item?.title ?? "Nothing Playing")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(item.map { "\($0.artist) • \($0.appName)" } ?? "No active media session")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)

            Text(isPinned ? "Pinned open" : "Hover preview")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var controlsBlock: some View {
        HStack(spacing: 8) {
            IslandActionButton(systemImage: "backward.fill", isPrimary: false, action: {
                nowPlayingState.previousTrack()
            })

            IslandActionButton(
                systemImage: item?.isPlaying == true ? "pause.fill" : "play.fill",
                isPrimary: true,
                action: {
                    nowPlayingState.playPause()
                }
            )

            IslandActionButton(systemImage: "forward.fill", isPrimary: false, action: {
                nowPlayingState.nextTrack()
            })
        }
    }
}


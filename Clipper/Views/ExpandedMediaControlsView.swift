//
//  ExpandedMediaControlsView.swift
//  Clipper
//
//  Created by Manu on 2026-04-19.
//


import SwiftUI

struct ExpandedMediaControlsView: View {
    @EnvironmentObject var nowPlayingState: NowPlayingState

    var body: some View {
        HStack(spacing: 16) {
            artworkBlock
            textBlock
            Spacer(minLength: 12)
            controlsBlock
        }
        .padding(.leading, 30)
        .padding(.trailing, 30)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .frame(width: 520, height: 108, alignment: .center)
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
                .truncationMode(.tail)

            Text(item.map { "\($0.artist) • \($0.appName)" } ?? "No active media session")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: 220, alignment: .leading)
    }

    private var controlsBlock: some View {
        HStack(spacing: 8) {
            IslandActionButton(systemImage: "backward.fill", isPrimary: false) {
                nowPlayingState.previousTrack()
            }

            IslandActionButton(
                systemImage: item?.isPlaying == true ? "pause.fill" : "play.fill",
                isPrimary: true
            ) {
                nowPlayingState.playPause()
            }

            IslandActionButton(systemImage: "forward.fill", isPrimary: false) {
                nowPlayingState.nextTrack()
            }
        }
    }
}

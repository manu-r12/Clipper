//
//  PeekIslandView.swift
//  Clipper
//
//  Created by Manu on 2026-04-19.
//

import SwiftUI

struct PeekIslandView: View {
    @EnvironmentObject var nowPlayingState: NowPlayingState

    var body: some View {
        HStack(spacing: 10) {
            playbackIndicator
            songInfo
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var item: NowPlayingItem? {
        nowPlayingState.item
    }

    private var playbackIndicator: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.14))

            Image(systemName: item?.isPlaying == true ? "pause.fill" : "play.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(width: 20, height: 20)
    }

    private var songInfo: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(item?.title ?? "No media playing")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.94))
                .lineLimit(1)
                .truncationMode(.tail)

            if let artist = item?.artist, !artist.isEmpty {
                Text(artist)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.50))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

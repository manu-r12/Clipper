//
//  ClosedIslandView.swift
//  Clipper
//
//  Created by Manu on 2026-04-18.
//


import SwiftUI

struct ClosedIslandView: View {
    @EnvironmentObject var nowPlayingState: NowPlayingState

    var body: some View {
        HStack(spacing: 8) {
            playbackIndicator
            titleLabel
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 10)
    }

    private var item: NowPlayingItem? {
        nowPlayingState.item
    }

    private var playbackIndicator: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.14))

            Image(systemName: item?.isPlaying == true ? "pause.fill" : "play.fill")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(width: 16, height: 16)
    }

    private var titleLabel: some View {
        Text(item?.title ?? "Nothing Playing")
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(.white.opacity(0.94))
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: 120, alignment: .leading)
    }
}

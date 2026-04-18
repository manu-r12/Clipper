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
            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 18, height: 18)
                .overlay(
                    Image(systemName: currentItem?.isPlaying == true ? "pause.fill" : "play.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                )

            Text(currentItem?.title ?? "Nothing Playing")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
        }
    }

    private var currentItem: NowPlayingItem? {
        nowPlayingState.item
    }
}

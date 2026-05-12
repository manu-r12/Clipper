//
//  NowPlayingItem.swift
//  Clipper
//
//  Created by Manu on 2026-04-18.
//

import AppKit

struct NowPlayingItem {
    let title: String
    let artist: String
    let appName: String
    let artwork: NSImage?
    let isPlaying: Bool
    let duration: Double       // total track length in seconds
    let elapsedTime: Double    // elapsed at lastUpdated
    let lastUpdated: Date      // when elapsedTime was sampled
    let playbackRate: Double   // 0 = paused, 1 = normal speed

    /// Elapsed time extrapolated to right now.
    /// Use this for the progress bar instead of `elapsedTime` directly.
    var estimatedElapsedTime: Double {
        guard isPlaying, duration > 0 else { return elapsedTime }
        let elapsed = elapsedTime + Date().timeIntervalSince(lastUpdated) * playbackRate
        return min(max(elapsed, 0), duration)
    }
}

//
//  MockNowPlayingProvider.swift
//  Clipper
//
//  Created by Manu on 2026-04-18.
//


import AppKit

final class MockNowPlayingProvider: NowPlayingProvider {
    private var items: [NowPlayingItem] = [
        NowPlayingItem(
            title: "Afterglow",
            artist: "Mock Artist",
            appName: "Music",
            artwork: nil,
            isPlaying: true
        ),
        NowPlayingItem(
            title: "Night Drive",
            artist: "Synth Avenue",
            appName: "Spotify",
            artwork: nil,
            isPlaying: true
        ),
        NowPlayingItem(
            title: "Signal Lost",
            artist: "North Static",
            appName: "Music",
            artwork: nil,
            isPlaying: false
        )
    ]

    private var currentIndex: Int = 0

    func currentItem() -> NowPlayingItem? {
        guard items.indices.contains(currentIndex) else { return nil }
        return items[currentIndex]
    }

    func playPause() {
        guard items.indices.contains(currentIndex) else { return }
        let current = items[currentIndex]

        items[currentIndex] = NowPlayingItem(
            title: current.title,
            artist: current.artist,
            appName: current.appName,
            artwork: current.artwork,
            isPlaying: !current.isPlaying
        )
    }

    func nextTrack() {
        guard !items.isEmpty else { return }
        currentIndex = (currentIndex + 1) % items.count
    }

    func previousTrack() {
        guard !items.isEmpty else { return }
        currentIndex = (currentIndex - 1 + items.count) % items.count
    }
}

//
//  NowPlayingState.swift
//  Clipper
//
//  Created by Manu on 2026-04-18.
//


import SwiftUI
import Combine

final class NowPlayingState: ObservableObject {
    @Published private(set) var item: NowPlayingItem?

    private let provider: NowPlayingProvider

    init(provider: NowPlayingProvider) {
        self.provider = provider
        self.item = provider.currentItem()
    }

    func refresh() {
        item = provider.currentItem()
    }

    func playPause() {
        provider.playPause()
        refresh()
    }

    func nextTrack() {
        provider.nextTrack()
        refresh()
    }

    func previousTrack() {
        provider.previousTrack()
        refresh()
    }
}

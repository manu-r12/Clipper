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
    @Published private(set) var flipAngle: Double = 0
    @Published private(set) var avgColor: NSColor = .gray

    private let provider: (any NowPlayingProvider)?
    private var cancellable: AnyCancellable?
    private var lastTitle: String = ""
    private var lastArtwork: NSImage?
    private var flipCooldownActive = false

    init(provider: (any NowPlayingProvider)?) {
        self.provider = provider
        guard let provider else { return }
        cancellable = provider.itemPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newItem in
                guard let self else { return }
                if let newItem, !newItem.title.isEmpty,
                   !self.lastTitle.isEmpty, newItem.title != self.lastTitle {
                    self.triggerFlip()
                }
                if let newItem { self.lastTitle = newItem.title }
                // Recompute avg color only when artwork actually changes
                if newItem?.artwork !== self.lastArtwork {
                    self.lastArtwork = newItem?.artwork
                    if let artwork = newItem?.artwork {
                        Task.detached(priority: .userInitiated) { [weak self] in
                            let color = artwork.averageColor
                            await MainActor.run { self?.avgColor = color }
                        }
                    } else {
                        self.avgColor = .gray
                    }
                }
                self.item = newItem
            }
    }

    func playPause()                { provider?.sendPlayPause() }
    func nextTrack()                { provider?.sendNextTrack() }
    func previousTrack()            { provider?.sendPreviousTrack() }
    func seek(to time: Double)      { provider?.sendSeek(to: time) }
    func toggleShuffle()            { provider?.sendToggleShuffle(currentlyShuffled: item?.isShuffled ?? false) }

    private func triggerFlip() {
        guard !flipCooldownActive else { return }
        flipCooldownActive = true
        withAnimation(.easeInOut(duration: 0.5)) {
            flipAngle += 180
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [weak self] in
            self?.flipCooldownActive = false
        }
    }
}

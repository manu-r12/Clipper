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

    private let provider: (any NowPlayingProvider)?
    private var cancellable: AnyCancellable?

    init(provider: (any NowPlayingProvider)?) {
        self.provider = provider
        guard let provider else { return }
        cancellable = provider.itemPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                self?.item = item
            }
    }

    func playPause()             { provider?.sendPlayPause() }
    func nextTrack()             { provider?.sendNextTrack() }
    func previousTrack()         { provider?.sendPreviousTrack() }
    func seek(to time: Double)   { provider?.sendSeek(to: time) }
}

//
//  NowPlayingProvider.swift
//  Clipper
//
//  Created by Manu on 2026-04-18.
//

import Combine
import Foundation

protocol NowPlayingProvider: AnyObject {
    /// Live stream of the current track. Sends `nil` when nothing is playing.
    var itemPublisher: AnyPublisher<NowPlayingItem?, Never> { get }

    func sendPlayPause()
    func sendNextTrack()
    func sendPreviousTrack()
    func sendSeek(to time: Double)
    func sendToggleShuffle(currentlyShuffled: Bool)
}

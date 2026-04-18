//
//  NowPlayingProvider.swift
//  Clipper
//
//  Created by Manu on 2026-04-18.
//


import Foundation

protocol NowPlayingProvider: AnyObject {
    func currentItem() -> NowPlayingItem?
    func playPause()
    func nextTrack()
    func previousTrack()
}

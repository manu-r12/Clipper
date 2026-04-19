//
//  AppDelegate.swift
//  Clipper
//
//  Created by Manu on 2026-04-14.
//

import Foundation
import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let islandState = IslandState()
    private let nowPlayingState = NowPlayingState(provider: MockNowPlayingProvider())
    private var panelController: IslandPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = IslandPanelController(
            state: islandState,
            nowPlayingState: nowPlayingState
        )
        controller.show()

        self.panelController = controller
    }
}

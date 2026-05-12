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
    private let nowPlayingState = NowPlayingState(provider: MediaRemoteNowPlayingProvider())
    private var panelController: IslandPanelController?
    private let statusBar = StatusBarController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusBar.setup()

        let controller = IslandPanelController(
            state: islandState,
            nowPlayingState: nowPlayingState
        )
        controller.show()

        self.panelController = controller
    }
}

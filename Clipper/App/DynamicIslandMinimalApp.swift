// DynamicIslandMinimalApp.swift
// Clipper
//
// Created by Manu on 2026-04-18.

import SwiftUI

@main
struct DynamicIslandMinimalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

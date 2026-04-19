//
//  IslandHaptics.swift
//  Clipper
//
//  Created by Manu on 2026-04-19.
//


import AppKit

enum IslandHaptics {
    static func peek() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }

    static func expand() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }
}

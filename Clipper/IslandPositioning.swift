// IslandPositioning.swift
// Clipper
//
// Created by Manu on 2026-04-18.

import CoreGraphics

import AppKit

enum IslandPositioning {
    static func size(for mode: IslandMode, on screen: NSScreen) -> CGSize {
        switch mode {
        case .closed:
            return closedPillSize(on: screen)

        case .expanded:
            return CGSize(width: 460, height: 96)
        }
    }

    static func closedPillSize(on screen: NSScreen) -> CGSize {
        let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY

        if #available(macOS 12.0, *), screen.safeAreaInsets.top > 0 {
            let leftInset = screen.auxiliaryTopLeftArea?.width ?? 0
            let rightInset = screen.auxiliaryTopRightArea?.width ?? 0

            let notchWidth = screen.frame.width - leftInset - rightInset + 4
            let notchHeight = max(screen.safeAreaInsets.top, menuBarHeight)

            return CGSize(width: notchWidth, height: notchHeight)
        } else {
            return CGSize(width: 180, height: max(32, menuBarHeight))
        }
    }

    static func topCenterFrame(for size: CGSize, on screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame

        let originX = screenFrame.midX - size.width / 2
        let originY = screenFrame.maxY - size.height

        return NSRect(
            x: originX,
            y: originY,
            width: size.width,
            height: size.height
        )
    }
}

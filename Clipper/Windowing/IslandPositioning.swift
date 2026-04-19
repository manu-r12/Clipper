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
            return closedNotchSize(on: screen)

        case .peek:
            return peekSize(on: screen)

        case .expanded:
            return CGSize(width: 460, height: 96)
        }
    }

    static func closedNotchSize(on screen: NSScreen) -> CGSize {
        var notchWidth: CGFloat = 185
        var notchHeight: CGFloat = 32

        if let leftArea = screen.auxiliaryTopLeftArea?.width,
           let rightArea = screen.auxiliaryTopRightArea?.width {
            notchWidth = screen.frame.width - leftArea - rightArea + 4
        }

        if screen.safeAreaInsets.top > 0 {
            notchHeight = screen.safeAreaInsets.top
        } else {
            notchHeight = screen.frame.maxY - screen.visibleFrame.maxY
        }

        return CGSize(width: notchWidth, height: notchHeight)
    }

    static func peekSize(on screen: NSScreen) -> CGSize {
        let base = closedNotchSize(on: screen)
        return CGSize(
            width: base.width + 58,
            height: base.height + 8
        )
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

    // Small rect that triggers peek from closed state.
    static func hoverActivationFrame(on screen: NSScreen) -> NSRect {
        let closed = topCenterFrame(for: closedNotchSize(on: screen), on: screen)
        return closed.insetBy(dx: -10, dy: 0)
    }

    // Stable larger rect that keeps peek alive.
    // Important: this is based on the target peek frame, not the live panel frame.
    static func hoverSustainFrame(on screen: NSScreen) -> NSRect {
        let peek = topCenterFrame(for: peekSize(on: screen), on: screen)
        return peek.insetBy(dx: -12, dy: -8)
    }
}

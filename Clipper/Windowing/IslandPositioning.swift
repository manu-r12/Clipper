// IslandPositioning.swift
// Clipper
//
// Created by Manu on 2026-04-18.

import CoreGraphics
import AppKit

enum IslandPositioning {
    static func size(
        for mode: IslandMode,
        on screen: NSScreen,
        expandedContent: ExpandedIslandContent?
    ) -> CGSize {
        switch mode {
        case .closed:
            return closedNotchSize(on: screen)

        case .peek:
            return peekSize(on: screen)

        case .expanded:
            return expandedSize(for: expandedContent ?? .media)
        }
    }

    static func closedNotchSize(on screen: NSScreen) -> CGSize {
        var notchWidth: CGFloat = 185
        var notchHeight: CGFloat = 32

        if let leftArea = screen.auxiliaryTopLeftArea?.width,
           let rightArea = screen.auxiliaryTopRightArea?.width,
           screen.safeAreaInsets.top > 0 {
            notchWidth = screen.frame.width - leftArea - rightArea + 4
        }

        if screen.safeAreaInsets.top > 0 {
            notchHeight = screen.safeAreaInsets.top
        } else {
            notchHeight = max(30, screen.frame.maxY - screen.visibleFrame.maxY)
        }

        return CGSize(width: notchWidth, height: notchHeight)
    }

    static func peekSize(on screen: NSScreen) -> CGSize {
        let base = closedNotchSize(on: screen)
        return CGSize(
            width: base.width + 58,
            height: base.height + 10
        )
    }

    static func expandedSize(for content: ExpandedIslandContent) -> CGSize {
        switch content {
        case .media:
            return CGSize(width: 420, height: 185)
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

    static func hoverActivationFrame(on screen: NSScreen) -> NSRect {
        let closed = topCenterFrame(for: closedNotchSize(on: screen), on: screen)
        return closed.insetBy(dx: -10, dy: 0)
    }

    static func hoverSustainFrame(on screen: NSScreen) -> NSRect {
        let peek = topCenterFrame(for: peekSize(on: screen), on: screen)
        return peek.insetBy(dx: -12, dy: -8)
    }
}

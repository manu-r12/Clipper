//
//  AdaptiveNotchShape.swift
//  Clipper
//
//  Created by Manu on 2026-04-19.
//
//  Matches Atoll's NotchShape exactly: a rounded rectangle whose two radii
//  interpolate smoothly via animatableData as the island transitions between modes.

import SwiftUI

struct AdaptiveNotchShape: Shape {
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(topCornerRadius, bottomCornerRadius) }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let t = topCornerRadius
        let b = bottomCornerRadius
        var path = Path()

        // Start at top-left (screen edge corner)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        // Top-left corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + t, y: rect.minY + t),
            control: CGPoint(x: rect.minX + t, y: rect.minY)
        )
        // Left side
        path.addLine(to: CGPoint(x: rect.minX + t, y: rect.maxY - b))
        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + t + b, y: rect.maxY),
            control: CGPoint(x: rect.minX + t, y: rect.maxY)
        )
        // Bottom
        path.addLine(to: CGPoint(x: rect.maxX - t - b, y: rect.maxY))
        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - t, y: rect.maxY - b),
            control: CGPoint(x: rect.maxX - t, y: rect.maxY)
        )
        // Right side
        path.addLine(to: CGPoint(x: rect.maxX - t, y: rect.minY + t))
        // Top-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.maxX - t, y: rect.minY)
        )
        // Top back to start
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))

        return path
    }
}

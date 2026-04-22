//
//  AdaptiveNotchShape.swift
//  Clipper
//
//  Created by Manu on 2026-04-19.
//


import SwiftUI

struct AdaptiveNotchShape: Shape {
    var shoulderInset: CGFloat
    var shoulderDepth: CGFloat
    var bottomRadius: CGFloat
    var shoulderTightness: CGFloat

    var animatableData: AnimatablePair<
        CGFloat,
        AnimatablePair<
            CGFloat,
            AnimatablePair<CGFloat, CGFloat>
        >
    > {
        get {
            AnimatablePair(
                shoulderInset,
                AnimatablePair(
                    shoulderDepth,
                    AnimatablePair(bottomRadius, shoulderTightness)
                )
            )
        }
        set {
            shoulderInset = newValue.first
            shoulderDepth = newValue.second.first
            bottomRadius = newValue.second.second.first
            shoulderTightness = newValue.second.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        let inset = min(max(shoulderInset, 8), w * 0.22)
        let depth = min(max(shoulderDepth, 4), h * 0.44)
        let radius = min(max(bottomRadius, 4), h * 0.44, (w - inset * 2) * 0.5)
        let tightness = min(max(shoulderTightness, 0), 1)

        let leftBodyX = inset
        let rightBodyX = w - inset

        let topY = rect.minY
        let shoulderY = rect.minY + depth
        let bottomY = rect.maxY

        let topControlPull = inset * (0.16 + 0.10 * tightness)
        let shoulderControlPull = inset * (0.84 + 0.08 * tightness)
        let shoulderVerticalPull = depth * (0.18 + 0.08 * tightness)
        let bottomArcSoftness = radius * 0.16

        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: topY))
        path.addLine(to: CGPoint(x: rect.maxX, y: topY))

        path.addCurve(
            to: CGPoint(x: rightBodyX, y: shoulderY),
            control1: CGPoint(x: rect.maxX - topControlPull, y: topY),
            control2: CGPoint(x: rect.maxX - shoulderControlPull, y: shoulderY - shoulderVerticalPull)
        )

        path.addLine(to: CGPoint(x: rightBodyX, y: bottomY - radius))

        path.addCurve(
            to: CGPoint(x: rightBodyX - radius, y: bottomY),
            control1: CGPoint(x: rightBodyX, y: bottomY - bottomArcSoftness),
            control2: CGPoint(x: rightBodyX - bottomArcSoftness, y: bottomY)
        )

        path.addLine(to: CGPoint(x: leftBodyX + radius, y: bottomY))

        path.addCurve(
            to: CGPoint(x: leftBodyX, y: bottomY - radius),
            control1: CGPoint(x: leftBodyX + bottomArcSoftness, y: bottomY),
            control2: CGPoint(x: leftBodyX, y: bottomY - bottomArcSoftness)
        )

        path.addLine(to: CGPoint(x: leftBodyX, y: shoulderY))

        path.addCurve(
            to: CGPoint(x: rect.minX, y: topY),
            control1: CGPoint(x: shoulderControlPull, y: shoulderY - shoulderVerticalPull),
            control2: CGPoint(x: topControlPull, y: topY)
        )

        path.closeSubpath()
        return path
    }
}

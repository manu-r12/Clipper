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

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(
                shoulderInset,
                AnimatablePair(shoulderDepth, bottomRadius)
            )
        }
        set {
            shoulderInset = newValue.first
            shoulderDepth = newValue.second.first
            bottomRadius = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        let inset = min(max(shoulderInset, 0), w * 0.25)
        let depth = min(max(shoulderDepth, 0), h * 0.6)
        let radius = min(max(bottomRadius, 0), h * 0.5, (w - inset * 2) * 0.5)

        let leftBodyX = inset
        let rightBodyX = w - inset

        var path = Path()

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))

        path.addCurve(
            to: CGPoint(x: rightBodyX, y: depth),
            control1: CGPoint(x: w - inset * 0.18, y: 0),
            control2: CGPoint(x: w - inset * 0.92, y: depth * 0.24)
        )

        path.addLine(to: CGPoint(x: rightBodyX, y: h - radius))

        path.addCurve(
            to: CGPoint(x: rightBodyX - radius, y: h),
            control1: CGPoint(x: rightBodyX, y: h - radius * 0.15),
            control2: CGPoint(x: rightBodyX - radius * 0.15, y: h)
        )

        path.addLine(to: CGPoint(x: leftBodyX + radius, y: h))

        path.addCurve(
            to: CGPoint(x: leftBodyX, y: h - radius),
            control1: CGPoint(x: leftBodyX + radius * 0.15, y: h),
            control2: CGPoint(x: leftBodyX, y: h - radius * 0.15)
        )

        path.addLine(to: CGPoint(x: leftBodyX, y: depth))

        path.addCurve(
            to: CGPoint(x: 0, y: 0),
            control1: CGPoint(x: leftBodyX * 0.92, y: depth * 0.24),
            control2: CGPoint(x: inset * 0.18, y: 0)
        )

        path.closeSubpath()
        return path
    }
}

//
//  ExpandedIslandShape.swift
//  Clipper
//
//  Created by Manu on 2026-04-19.
//


import SwiftUI

struct ExpandedIslandShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        let shoulderInset = min(max(w * 0.10, 18), 34)
        let shoulderDepth = min(max(h * 0.16, 10), 18)
        let bottomRadius = min(max(h * 0.22, 18), 26)

        let leftBodyX = shoulderInset
        let rightBodyX = w - shoulderInset

        var path = Path()

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))

        path.addCurve(
            to: CGPoint(x: rightBodyX, y: shoulderDepth),
            control1: CGPoint(x: w - shoulderInset * 0.20, y: 0),
            control2: CGPoint(x: w - shoulderInset * 0.92, y: shoulderDepth * 0.30)
        )

        path.addLine(to: CGPoint(x: rightBodyX, y: h - bottomRadius))

        path.addCurve(
            to: CGPoint(x: rightBodyX - bottomRadius, y: h),
            control1: CGPoint(x: rightBodyX, y: h - bottomRadius * 0.15),
            control2: CGPoint(x: rightBodyX - bottomRadius * 0.15, y: h)
        )

        path.addLine(to: CGPoint(x: leftBodyX + bottomRadius, y: h))

        path.addCurve(
            to: CGPoint(x: leftBodyX, y: h - bottomRadius),
            control1: CGPoint(x: leftBodyX + bottomRadius * 0.15, y: h),
            control2: CGPoint(x: leftBodyX, y: h - bottomRadius * 0.15)
        )

        path.addLine(to: CGPoint(x: leftBodyX, y: shoulderDepth))

        path.addCurve(
            to: CGPoint(x: 0, y: 0),
            control1: CGPoint(x: leftBodyX * 0.92, y: shoulderDepth * 0.30),
            control2: CGPoint(x: shoulderInset * 0.20, y: 0)
        )

        path.closeSubpath()
        return path
    }
}

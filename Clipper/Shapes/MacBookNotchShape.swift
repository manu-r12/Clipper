//
//  MacBookNotchShape.swift
//  Clipper
//
//  Created by Manu on 2026-04-19.
//


import SwiftUI

struct MacBookHardwareNotchShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        let shoulderInset = min(max(w * 0.115, 14), 22)
        let shoulderDepth = min(max(h * 0.34, 8), 13)
        let bottomRadius = min(max(h * 0.30, 8), 12)

        let leftBodyX = shoulderInset
        let rightBodyX = w - shoulderInset

        var path = Path()

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))

        path.addCurve(
            to: CGPoint(x: rightBodyX, y: shoulderDepth),
            control1: CGPoint(x: w - shoulderInset * 0.18, y: 0),
            control2: CGPoint(x: w - shoulderInset * 0.92, y: shoulderDepth * 0.22)
        )

        path.addLine(to: CGPoint(x: rightBodyX, y: h - bottomRadius))

        path.addCurve(
            to: CGPoint(x: rightBodyX - bottomRadius, y: h),
            control1: CGPoint(x: rightBodyX, y: h - bottomRadius * 0.18),
            control2: CGPoint(x: rightBodyX - bottomRadius * 0.18, y: h)
        )

        path.addLine(to: CGPoint(x: leftBodyX + bottomRadius, y: h))

        path.addCurve(
            to: CGPoint(x: leftBodyX, y: h - bottomRadius),
            control1: CGPoint(x: leftBodyX + bottomRadius * 0.18, y: h),
            control2: CGPoint(x: leftBodyX, y: h - bottomRadius * 0.18)
        )

        path.addLine(to: CGPoint(x: leftBodyX, y: shoulderDepth))

        path.addCurve(
            to: CGPoint(x: 0, y: 0),
            control1: CGPoint(x: leftBodyX * 0.92, y: shoulderDepth * 0.22),
            control2: CGPoint(x: shoulderInset * 0.18, y: 0)
        )

        path.closeSubpath()
        return path
    }
}

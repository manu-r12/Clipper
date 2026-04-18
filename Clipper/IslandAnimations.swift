//
//  IslandAnimations.swift
//  Clipper
//
//  Created by Manu on 2026-04-18.
//


import SwiftUI

enum IslandAnimations {
    static let shellSpring = Animation.spring(
        response: 0.44,
        dampingFraction: 0.86,
        blendDuration: 0.12
    )

    static let contentSpring = Animation.spring(
        response: 0.34,
        dampingFraction: 0.88,
        blendDuration: 0.10
    )
}

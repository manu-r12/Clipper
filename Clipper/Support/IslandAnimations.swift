//
//  IslandAnimations.swift
//  Clipper
//
//  Created by Manu on 2026-04-18.
//


import SwiftUI

enum IslandAnimations {
    static let shellSpring = Animation.interpolatingSpring(
        mass: 0.9,
        stiffness: 170,
        damping: 18,
        initialVelocity: 0
    )

    static let peekSpring = Animation.interpolatingSpring(
        mass: 0.7,
        stiffness: 220,
        damping: 20,
        initialVelocity: 0
    )

    static let contentSpring = Animation.easeInOut(duration: 0.18)
}

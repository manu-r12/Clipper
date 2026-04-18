//
//  IslandActionButton.swift
//  Clipper
//
//  Created by Manu on 2026-04-18.
//

import SwiftUI

struct IslandActionButton: View {
    let systemImage: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isPrimary ? .black : .white)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(isPrimary ? Color.white : Color.white.opacity(0.10))
                )
        }
        .buttonStyle(.plain)
    }
}

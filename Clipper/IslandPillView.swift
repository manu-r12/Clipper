// IslandPillView.swift
// Clipper
//
// Created by Manu on 2026-04-18.

import SwiftUI


struct IslandPillView: View {
    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Color.black)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            HStack(spacing: 8) {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 8, height: 8)

                Text("Dynamic Island")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.92))
            }
            .padding(.horizontal, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

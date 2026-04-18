//
//  IslandRootView.swift
//  Clipper
//
//  Created by Manu on 2026-04-18.
//


import SwiftUI

struct IslandRootView: View {
    @EnvironmentObject var state: IslandState
    @State private var pressed = false

    private var isClosed: Bool {
        state.currentMode == .closed
    }

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let cornerRadius = isClosed ? height / 2 : 28
            let horizontalPadding = isClosed ? 14.0 : 16.0
            let verticalPadding = isClosed ? 6.0 : 12.0

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black)
                    .shadow(
                        color: .black.opacity(isClosed ? 0.10 : 0.18),
                        radius: isClosed ? 8 : 14,
                        y: isClosed ? 3 : 6
                    )
                    .scaleEffect(pressed ? 0.985 : 1.0)
                    .animation(IslandAnimations.shellSpring, value: isClosed)
                    .animation(IslandAnimations.shellSpring, value: pressed)

                Group {
                    if isClosed {
                        ClosedIslandView()
                            .padding(.horizontal, horizontalPadding)
                            .padding(.vertical, verticalPadding)
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.97)),
                                    removal: .opacity.combined(with: .scale(scale: 0.985))
                                )
                            )
                    } else {
                        ExpandedIslandView(isPinned: state.isPinnedOpen)
                            .padding(.horizontal, horizontalPadding)
                            .padding(.vertical, verticalPadding)
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.985)),
                                    removal: .opacity.combined(with: .scale(scale: 0.98))
                                )
                            )
                    }
                }
                .animation(IslandAnimations.contentSpring, value: state.currentMode)
                .animation(IslandAnimations.contentSpring, value: state.isPinnedOpen)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .compositingGroup()
            .contentShape(Rectangle())
            .onTapGesture {
                state.togglePinnedOpen()
            }
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: 20,
                pressing: { isPressing in
                    pressed = isPressing
                },
                perform: {}
            )
        }
    }
}

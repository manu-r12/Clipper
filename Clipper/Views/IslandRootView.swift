//
//  IslandRootView.swift
//  Clipper
//
//  Created by Manu on 2026-04-18.
//


import SwiftUI
import AppKit

struct IslandRootView: View {
    @EnvironmentObject var state: IslandState
    @EnvironmentObject var nowPlayingState: NowPlayingState
    @State private var pressed = false
    @State private var lastHapticTime: Date = .distantPast

    private var shapeParameters: (shoulderInset: CGFloat, shoulderDepth: CGFloat, bottomRadius: CGFloat) {
        switch state.currentMode {
        case .closed:
            return (16, 10, 10)
        case .peek:
            return (17, 10.5, 13)
        case .expanded:
            return (28, 16, 24)
        }
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                AdaptiveNotchShape(
                    shoulderInset: shapeParameters.shoulderInset,
                    shoulderDepth: shapeParameters.shoulderDepth,
                    bottomRadius: shapeParameters.bottomRadius
                )
                .fill(Color.black)
                .shadow(
                    color: state.currentMode == .expanded ? .black.opacity(0.12) : .clear,
                    radius: state.currentMode == .expanded ? 12 : 0,
                    y: state.currentMode == .expanded ? 5 : 0
                )
                .scaleEffect(pressed ? 0.985 : (state.currentMode == .peek ? 1.003 : 1.0))
                .animation(
                    state.currentMode == .peek ? IslandAnimations.peekSpring : IslandAnimations.shellSpring,
                    value: state.currentMode
                )
                .animation(IslandAnimations.peekSpring, value: pressed)

                Group {
                    switch state.currentMode {
                    case .closed:
                        ClosedIslandView()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .transition(.opacity)

                    case .peek:
                        PeekIslandView()
                            .padding(.horizontal, 0)
                            .padding(.vertical, 0)
                            .transition(.opacity)

                    case .expanded:
                        ExpandedIslandView(isPinned: state.isPinnedOpen)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
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
                state.expandFromUserAction()
            }
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: 20,
                pressing: { isPressing in
                    pressed = isPressing
                },
                perform: {}
            )
            .onChange(of: state.currentMode) { _, newMode in
                if newMode == .peek {
                    triggerPeekHapticIfAllowed()
                } else if newMode == .expanded {
                    IslandHaptics.expand()
                }
            }
        }
    }

    private func triggerPeekHapticIfAllowed() {
        let now = Date()
        guard now.timeIntervalSince(lastHapticTime) > 0.20 else { return }

        IslandHaptics.peek()
        lastHapticTime = now
    }
}

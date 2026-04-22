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
    @State private var showExpandedContent = false
    @State private var expandedRevealTask: Task<Void, Never>?

    private var shapeParameters: (
        shoulderInset: CGFloat,
        shoulderDepth: CGFloat,
        bottomRadius: CGFloat,
        shoulderTightness: CGFloat
    ) {
        switch state.currentMode {
        case .closed:
            return (16, 10, 10, 0.82)

        case .peek:
            return (18, 11, 14, 0.86)

        case .expanded:
            return (22, 12.5, 18, 0.92)
        }
    }

    private var currentShape: AdaptiveNotchShape {
        AdaptiveNotchShape(
            shoulderInset: shapeParameters.shoulderInset,
            shoulderDepth: shapeParameters.shoulderDepth,
            bottomRadius: shapeParameters.bottomRadius,
            shoulderTightness: shapeParameters.shoulderTightness
        )
    }

    var body: some View {
        ZStack {
            shellLayer

            closedLayer
            peekLayer
            expandedLayer
        }        .clipShape(currentShape)
        .scaleEffect(pressed ? 0.985 : (state.currentMode == .peek ? 1.002 : 1.0))
        .animation(
            state.currentMode == .peek ? IslandAnimations.peekSpring : IslandAnimations.shellSpring,
            value: state.currentMode
        )
        .animation(IslandAnimations.peekSpring, value: pressed)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .compositingGroup()
        .contentShape(Rectangle())
        .onTapGesture {
            if state.currentMode != .expanded {
                state.expandFromUserAction()
            }
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
            handleModeChange(newMode)

            if newMode == .peek {
                triggerPeekHapticIfAllowed()
            }
        }
        .onAppear {
            handleModeChange(state.currentMode)
        }
    }
    
    private var shellLayer: some View {
        currentShape
            .fill(
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.025, green: 0.025, blue: 0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                currentShape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.015)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.65
                    )
            }
            .overlay(alignment: .bottom) {
                currentShape
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                Color.white.opacity(state.currentMode == .expanded ? 0.045 : 0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blur(radius: 18)
                    .mask(currentShape)
            }
            .shadow(
                color: state.currentMode == .expanded ? .black.opacity(0.18) : .clear,
                radius: state.currentMode == .expanded ? 14 : 0,
                y: state.currentMode == .expanded ? 5 : 0
            )
    }

    private var closedLayer: some View {
        ClosedIslandView()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(state.currentMode == .closed ? 1 : 0)
            .animation(.easeInOut(duration: 0.10), value: state.currentMode)
            .allowsHitTesting(state.currentMode == .closed)
    }

    private var peekLayer: some View {
        PeekIslandView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(state.currentMode == .peek ? 1 : 0)
            .animation(.easeInOut(duration: 0.10), value: state.currentMode)
            .allowsHitTesting(state.currentMode == .peek)
    }

    private var expandedLayer: some View {
        Group {
            if state.currentMode == .expanded,
               showExpandedContent,
               let expandedContent = state.expandedContent {
                expandedContentView(for: expandedContent)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(
                        .opacity
                        .combined(with: .blurReplace)
                        .animation(.easeInOut(duration: 0.16))
                    )
            }
        }
        .allowsHitTesting(state.currentMode == .expanded)
    }

    @ViewBuilder
    private func expandedContentView(for content: ExpandedIslandContent) -> some View {
        switch content {
        case .media:
            ExpandedMediaControlsView()
                .environmentObject(nowPlayingState)
        }
    }

    private func handleModeChange(_ mode: IslandMode) {
        expandedRevealTask?.cancel()

        switch mode {
        case .closed, .peek:
            withAnimation(.easeOut(duration: 0.08)) {
                showExpandedContent = false
            }

        case .expanded:
            showExpandedContent = false

            expandedRevealTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(90))
                guard !Task.isCancelled else { return }
                guard state.currentMode == .expanded else { return }

                withAnimation(.easeInOut(duration: 0.16)) {
                    showExpandedContent = true
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

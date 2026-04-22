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

    private var shapeParameters: (shoulderInset: CGFloat, shoulderDepth: CGFloat, bottomRadius: CGFloat) {
        switch state.currentMode {
        case .closed:
            return (16, 10, 10)

        case .peek:
            return (17, 10.5, 13)

        case .expanded:
            return (18, 12, 24)
        }
    }

    private var currentShape: AdaptiveNotchShape {
        AdaptiveNotchShape(
            shoulderInset: shapeParameters.shoulderInset,
            shoulderDepth: shapeParameters.shoulderDepth,
            bottomRadius: shapeParameters.bottomRadius
        )
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                currentShape
                    .fill(Color.black)
                    .shadow(
                        color: state.currentMode == .expanded ? .black.opacity(0.12) : .clear,
                        radius: state.currentMode == .expanded ? 12 : 0,
                        y: state.currentMode == .expanded ? 5 : 0
                    )

                closedLayer
                peekLayer
                expandedLayer
            }
            .clipShape(currentShape)
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
                handleModeChange(newMode)

                if newMode == .peek {
                    triggerPeekHapticIfAllowed()
                }
            }
            .onAppear {
                handleModeChange(state.currentMode)
            }
        }
    }

    private var closedLayer: some View {
        ClosedIslandView()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .opacity(state.currentMode == .closed ? 1 : 0)
            .animation(.easeInOut(duration: 0.10), value: state.currentMode)
            .allowsHitTesting(state.currentMode == .closed)
    }

    private var peekLayer: some View {
        PeekIslandView()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .opacity(state.currentMode == .peek ? 1 : 0)
            .animation(.easeInOut(duration: 0.10), value: state.currentMode)
            .allowsHitTesting(state.currentMode == .peek)
    }

    private var expandedLayer: some View {
        Group {
            if showExpandedContent {
                ExpandedMediaControlsView()
                    .environmentObject(nowPlayingState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .transition(
                        .opacity
                        .combined(with: .blurReplace)
                        .animation(.interactiveSpring(dampingFraction: 1.0))
                    )
            }
        }
        .allowsHitTesting(state.currentMode == .expanded)
    }

    private func handleModeChange(_ mode: IslandMode) {
        expandedRevealTask?.cancel()

        switch mode {
        case .closed, .peek:
            withAnimation(.easeOut(duration: 0.08)) {
                showExpandedContent = false
            }

        case .expanded:
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

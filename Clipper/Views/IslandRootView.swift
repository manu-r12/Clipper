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

    // MARK: - Target size (drives the animated inner frame)

    // SwiftUI reads this every render pass and animates transitions via
    // .animation(_:value:) when currentMode or expandedContent changes.
    private var targetSize: CGSize {
        guard let screen = NSScreen.main else {
            return CGSize(width: 185, height: 32)
        }
        return IslandPositioning.size(
            for: state.currentMode,
            on: screen,
            expandedContent: state.expandedContent
        )
    }

    // MARK: - Shape parameters
    // Radii match Atoll's cornerRadiusInsets: closed (top=6, bottom=14), open (top=19, bottom=24).

    private var currentShape: AdaptiveNotchShape {
        switch state.currentMode {
        case .closed:   return AdaptiveNotchShape(topCornerRadius: 6,  bottomCornerRadius: 14)
        case .peek:     return AdaptiveNotchShape(topCornerRadius: 10, bottomCornerRadius: 18)
        case .expanded: return AdaptiveNotchShape(topCornerRadius: 35, bottomCornerRadius: 35)
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            shellLayer
            closedLayer
            peekLayer
            expandedLayer
        }
        // Inner frame: animates between closed/peek/expanded sizes.
        // The panel is fixed at expanded-size + shadow padding; content grows downward from the top edge.
        .frame(width: targetSize.width, height: targetSize.height, alignment: .top)
        .clipped()
        .drawingGroup()
        .clipShape(currentShape)
        .compositingGroup()
        // Shadow lives outside clipShape so it renders around (not clipped by) the notch shape.
        .shadow(
            color: state.currentMode == .expanded ? .black.opacity(0.18) : .clear,
            radius: state.currentMode == .expanded ? 14 : 0,
            y: state.currentMode == .expanded ? 5 : 0
        )
        .scaleEffect(pressed ? 0.985 : (state.currentMode == .peek ? 1.002 : 1.0))
        // Single spring drives the whole transition: frame growth, shape morph, shadow, scale.
        .animation(
            state.currentMode == .peek ? IslandAnimations.peekSpring : IslandAnimations.shellSpring,
            value: state.currentMode
        )
        .animation(IslandAnimations.shellSpring, value: state.expandedContent)
        .animation(IslandAnimations.peekSpring, value: pressed)
        // Hit testing limited to the visible notch shape, not the full panel.
        .contentShape(currentShape)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { value in
                    pressed = false
                    let d = value.translation
                    guard d.width * d.width + d.height * d.height < 400 else { return }
                    if state.currentMode != .expanded {
                        state.expandFromUserAction()
                    }
                }
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
        // Outer frame: fills the fixed panel, content anchored to the top (screen edge).
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Layers

    private var shellLayer: some View {
        currentShape
            .fill(Color.black)
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

    // MARK: - Mode transitions

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

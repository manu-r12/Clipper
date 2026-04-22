// IslandPanelController.swift
// Clipper
//
// Created by Manu on 2026-04-18.

import AppKit
import SwiftUI
import Combine

@MainActor
final class IslandPanelController {
    private let state: IslandState
    private let nowPlayingState: NowPlayingState

    private var panel: IslandPanel?
    private var cancellables = Set<AnyCancellable>()
    private var hoverTimer: Timer?
    private var globalClickMonitor: Any?
    private var localKeyMonitor: Any?

    init(state: IslandState, nowPlayingState: NowPlayingState) {
        self.state = state
        self.nowPlayingState = nowPlayingState
        bindState()
    }

    deinit {
        hoverTimer?.invalidate()

        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
        }

        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
        }
    }

    func show() {
        if panel == nil {
            let newPanel = IslandPanel(frame: .zero)
            newPanel.contentViewController = NSHostingController(
                rootView: IslandRootView()
                    .environmentObject(state)
                    .environmentObject(nowPlayingState)
            )
            panel = newPanel
        }

        reposition(animated: false)
        panel?.orderFrontRegardless()

        startHoverPolling()
        installOutsideClickMonitor()
        installEscapeKeyMonitor()
    }

    private func bindState() {
        state.$mode
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reposition(animated: true)
            }
            .store(in: &cancellables)

        state.$expandedContent
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard self?.state.currentMode == .expanded else { return }
                self?.reposition(animated: true)
            }
            .store(in: &cancellables)

        state.$isPinnedOpen
            .receive(on: RunLoop.main)
            .sink { [weak self] isPinned in
                self?.updateKeyFocus(for: isPinned)
            }
            .store(in: &cancellables)
    }

    private func updateKeyFocus(for isPinned: Bool) {
        guard let panel else { return }

        if isPinned {
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
        } else {
            panel.orderFrontRegardless()
        }
    }

    private func installEscapeKeyMonitor() {
        guard localKeyMonitor == nil else { return }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else { return event }

            if event.keyCode == 53, self.state.isPinnedOpen {
                self.state.closeAll()
                return nil
            }

            return event
        }
    }

    private func reposition(animated: Bool) {
        guard let panel, let screen = NSScreen.main else { return }

        let size = IslandPositioning.size(
            for: state.currentMode,
            on: screen,
            expandedContent: state.expandedContent
        )

        let frame = IslandPositioning.topCenterFrame(for: size, on: screen)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = animationDuration(for: state.currentMode)
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.85, 0.25, 1.0)
                panel.animator().setFrame(frame, display: true)
            }
            // Use setFrameTopLeftPoint to ensure the top edge remains pinned during transitions
            DispatchQueue.main.async {
                panel.setFrameTopLeftPoint(NSPoint(x: frame.origin.x, y: frame.origin.y + frame.size.height))
            }
        } else {
            // Use setFrameTopLeftPoint to ensure the top edge remains pinned during transitions
            panel.setFrameTopLeftPoint(NSPoint(x: frame.origin.x, y: frame.origin.y + frame.size.height))
        }
    }

    private func animationDuration(for mode: IslandMode) -> TimeInterval {
        switch mode {
        case .closed:
            return 0.30
        case .peek:
            return 0.24
        case .expanded:
            return 0.36
        }
    }

    private func startHoverPolling() {
        hoverTimer?.invalidate()

        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { _ in
            Task { @MainActor [weak self] in
                self?.updateHoverState()
            }
        }

        hoverTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func updateHoverState() {
        guard let screen = NSScreen.main else { return }

        let mouseLocation = NSEvent.mouseLocation

        let activationFrame = IslandPositioning.hoverActivationFrame(on: screen)
        let sustainFrame = IslandPositioning.hoverSustainFrame(on: screen)

        let pointerInActivation = activationFrame.contains(mouseLocation)
        let pointerInSustain = sustainFrame.contains(mouseLocation)

        state.releaseReopenLatchIfNeeded(pointerInActivationRect: pointerInActivation)

        switch state.currentMode {
        case .closed:
            if pointerInActivation {
                state.requestHoverPeek()
            } else {
                state.cancelPendingPeek()
            }

        case .peek:
            if pointerInSustain {
                state.cancelPendingClose()
            } else {
                state.requestHoverClose()
            }

        case .expanded:
            break
        }
    }

    private func installOutsideClickMonitor() {
        guard globalClickMonitor == nil else { return }

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.state.closeFromOutsideClick()
            }
        }
    }
}


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

    // Extra space below the expanded content so the drop shadow doesn't clip at the panel edge.
    private static let shadowPadding: CGFloat = 20

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

        // Set the panel once to the maximum (expanded) size and never resize it again.
        // All visual animation is owned by SwiftUI inside the panel.
        repositionToMaxFrame()
        panel?.orderFrontRegardless()

        startHoverPolling()
        installOutsideClickMonitor()
        installEscapeKeyMonitor()
    }

    // MARK: - Panel positioning

    // The panel is always the expanded size + shadow padding.
    // SwiftUI animates the inner content frame between modes — the panel itself never moves.
    private func repositionToMaxFrame() {
        guard let panel, let screen = NSScreen.main else { return }

        let expandedSize = IslandPositioning.expandedSize(for: .media)
        let pad = IslandPanelController.shadowPadding
        let panelWidth  = expandedSize.width  + pad * 2
        let panelHeight = expandedSize.height + pad

        let screenFrame = screen.frame
        let originX = screenFrame.midX - panelWidth / 2
        let originY = screenFrame.maxY - panelHeight

        panel.setFrame(NSRect(x: originX, y: originY, width: panelWidth, height: panelHeight), display: true)
    }

    // MARK: - State binding

    private func bindState() {
        // Only update key focus when the pin state changes; visual transitions are SwiftUI's job.
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

    // MARK: - Input monitors

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

    // MARK: - Hover polling

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
}

//
//  IslandState.swift
//  Clipper
//
//  Created by Manu on 2026-04-18.
//


import SwiftUI
import Combine

final class IslandState: ObservableObject {
    @Published private(set) var mode: IslandMode = .closed
    @Published private(set) var isPinnedOpen: Bool = false

    private var pendingOpenTask: Task<Void, Never>?
    private var pendingCloseTask: Task<Void, Never>?

    private(set) var reopenRequiresExit = false

    private let hoverOpenDelay: Duration = .milliseconds(120)
    private let hoverCloseDelay: Duration = .milliseconds(160)

    var currentMode: IslandMode { mode }

    func requestHoverOpen() {
        guard mode == .closed else { return }
        guard !isPinnedOpen else { return }
        guard !reopenRequiresExit else { return }

        pendingCloseTask?.cancel()

        if pendingOpenTask != nil { return }

        pendingOpenTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.pendingOpenTask = nil }

            try? await Task.sleep(for: hoverOpenDelay)
            guard !Task.isCancelled else { return }
            guard !self.isPinnedOpen else { return }

            withAnimation(IslandAnimations.shellSpring) {
                self.mode = .expanded
            }
        }
    }

    func cancelPendingOpen() {
        pendingOpenTask?.cancel()
        pendingOpenTask = nil
    }

    func requestHoverClose() {
        guard mode == .expanded else { return }
        guard !isPinnedOpen else { return }

        pendingOpenTask?.cancel()

        if pendingCloseTask != nil { return }

        pendingCloseTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.pendingCloseTask = nil }

            try? await Task.sleep(for: hoverCloseDelay)
            guard !Task.isCancelled else { return }
            guard !self.isPinnedOpen else { return }

            withAnimation(IslandAnimations.shellSpring) {
                self.mode = .closed
            }

            self.reopenRequiresExit = true
        }
    }

    func cancelPendingClose() {
        pendingCloseTask?.cancel()
        pendingCloseTask = nil
    }

    func releaseReopenLatchIfNeeded(pointerInActivationRect: Bool) {
        if reopenRequiresExit && !pointerInActivationRect {
            reopenRequiresExit = false
        }
    }

    func togglePinnedOpen() {
        cancelPendingOpen()
        cancelPendingClose()

        if isPinnedOpen {
            isPinnedOpen = false
            reopenRequiresExit = true

            withAnimation(IslandAnimations.shellSpring) {
                mode = .closed
            }
        } else {
            isPinnedOpen = true
            reopenRequiresExit = false

            withAnimation(IslandAnimations.shellSpring) {
                mode = .expanded
            }
        }
    }

    func closeFromOutsideClick() {
        guard isPinnedOpen else { return }
        closeAll()
    }
    
    func closeAll() {
        cancelPendingOpen()
        cancelPendingClose()

        isPinnedOpen = false
        reopenRequiresExit = true

        withAnimation(IslandAnimations.shellSpring) {
            mode = .closed
        }
    }
}

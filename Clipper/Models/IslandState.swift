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

    private var pendingPeekTask: Task<Void, Never>?
    private var pendingCloseTask: Task<Void, Never>?

    private(set) var reopenRequiresExit = false

    private let hoverPeekDelay: Duration = .milliseconds(85)
    private let hoverCloseDelay: Duration = .milliseconds(180)

    var currentMode: IslandMode { mode }

    func requestHoverPeek() {
        guard mode == .closed else { return }
        guard !isPinnedOpen else { return }
        guard !reopenRequiresExit else { return }

        pendingCloseTask?.cancel()

        if pendingPeekTask != nil { return }

        pendingPeekTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.pendingPeekTask = nil }

            try? await Task.sleep(for: hoverPeekDelay)
            guard !Task.isCancelled else { return }
            guard !self.isPinnedOpen else { return }
            guard self.mode == .closed else { return }

            withAnimation(IslandAnimations.peekSpring) {
                self.mode = .peek
            }
        }
    }

    func cancelPendingPeek() {
        pendingPeekTask?.cancel()
        pendingPeekTask = nil
    }

    func requestHoverClose() {
        guard mode == .peek else { return }
        guard !isPinnedOpen else { return }

        pendingPeekTask?.cancel()

        if pendingCloseTask != nil { return }

        pendingCloseTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.pendingCloseTask = nil }

            try? await Task.sleep(for: hoverCloseDelay)
            guard !Task.isCancelled else { return }
            guard !self.isPinnedOpen else { return }
            guard self.mode == .peek else { return }

            withAnimation(IslandAnimations.peekSpring) {
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

    func expandFromUserAction() {
        cancelPendingPeek()
        cancelPendingClose()

        isPinnedOpen = true
        reopenRequiresExit = false

        withAnimation(IslandAnimations.shellSpring) {
            mode = .expanded
        }
    }

    func closeAll() {
        cancelPendingPeek()
        cancelPendingClose()

        isPinnedOpen = false
        reopenRequiresExit = true

        withAnimation(IslandAnimations.shellSpring) {
            mode = .closed
        }
    }

    func closeFromOutsideClick() {
        guard isPinnedOpen else { return }
        closeAll()
    }
}

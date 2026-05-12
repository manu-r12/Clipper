//
//  StatusBarController.swift
//  Clipper
//

import AppKit

final class StatusBarController {
    private var statusItem: NSStatusItem?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.topthird.inset.filled", accessibilityDescription: "Clipper")
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Quit Clipper", action: #selector(quit), keyEquivalent: "q")
            .target = self

        statusItem?.menu = menu
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

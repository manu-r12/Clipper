import AppKit
import SwiftUI
import Carbon.HIToolbox   // For RegisterEventHotKey, kVK_*, etc.

/// Manages the menu bar icon, the NSPopover, and the global Cmd+Shift+V hotkey.
/// This is the top-level AppKit controller; it owns the SwiftUI layer.
final class MenuBarController: NSObject {

    // MARK: - Properties

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?          // local event monitor (click-outside to close)
    private var hotKeyRef: EventHotKeyRef?  // Carbon hotkey handle

    private let store: ClipboardStore
    private let viewModel: ClipboardViewModel

    // MARK: - Init

    init(store: ClipboardStore) {
        self.store = store
        self.viewModel = ClipboardViewModel(store: store)
        super.init()
        setupStatusItem()
        setupPopover()
        registerGlobalHotKey()
    }

    // MARK: - Menu bar icon

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            // SF Symbol for the icon; fallback to plain text.
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard History")
            button.image?.size = NSSize(width: 16, height: 16)
            button.image?.isTemplate = true   // adapts to light/dark menu bar automatically
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 420, height: 520)
        popover.behavior = .transient   // closes when user clicks elsewhere
        popover.animates = true

        // Host SwiftUI ContentView inside the popover.
        let rootView = ContentView(vm: viewModel) { [weak self] in
            self?.closePopover()
        }
        popover.contentViewController = NSHostingController(rootView: rootView)
    }

    // MARK: - Toggle

    @objc func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            openPopover()
        }
    }

    func openPopover() {
        guard let button = statusItem.button else { return }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        // Give SwiftUI a moment to layout, then focus the window so keyboard events land.
        DispatchQueue.main.async { [weak self] in
            self?.popover.contentViewController?.view.window?.makeKey()
        }

        // Monitor clicks outside the popover to close it (belt + suspenders with .transient).
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    func closePopover() {
        popover.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - Global hotkey: Cmd + Shift + V  (Carbon RegisterEventHotKey)
    //
    // Why Carbon?  NSEvent.addGlobalMonitorForEvents cannot capture key-down events system-wide
    // when the app is in the background.  Carbon's RegisterEventHotKey IS designed for this.
    // The approach:
    //   1. Install an EventHandler on the application event target.
    //   2. Register a HotKey ID bound to Cmd+Shift+V.
    //   3. The handler calls back into our Swift code to toggle the popover.

    private func registerGlobalHotKey() {
        // Install the Carbon event handler on the application target.
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        // We pass `self` as userData so the C callback can reach our instance.
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                // Retrieve the MenuBarController instance from userData.
                guard let ptr = userData else { return OSStatus(eventNotHandledErr) }
                let controller = Unmanaged<MenuBarController>.fromOpaque(ptr).takeUnretainedValue()

                // Verify this is our registered hotkey (ID 1).
                var hotkeyID = EventHotKeyID()
                GetEventParameter(event,
                                  EventParamName(kEventParamDirectObject),
                                  EventParamType(typeEventHotKeyID),
                                  nil,
                                  MemoryLayout<EventHotKeyID>.size,
                                  nil,
                                  &hotkeyID)

                if hotkeyID.id == 1 {
                    // Must dispatch to main queue — Carbon callbacks arrive on a background thread.
                    DispatchQueue.main.async { controller.togglePopover() }
                }
                return noErr
            },
            1,              // number of event types
            &eventSpec,
            selfPtr,
            nil             // we don't need the handler ref
        )

        // Register Cmd + Shift + V.
        // kVK_ANSI_V = 0x09, cmdKey | shiftKey are Carbon modifier masks.
        var hotkeyID = EventHotKeyID(signature: OSType(0x4348_4D48), id: 1) // 'CHMH'
        RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey | shiftKey),
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    deinit {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
    }
}

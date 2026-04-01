import AppKit
import SwiftUI
import Combine

// MARK: - HUD State

enum HUDState: Equatable {
    case hidden
    case expanded
    case collapsed
}

// MARK: - NotchWindowController

/// Places a borderless NSPanel flush with the top of the screen.
/// On hover near the notch it springs open to full screen width —
/// the notch disappears into the black bar (same colour trick used by Notchmeister).
final class NotchWindowController: NSObject {

    // MARK: - Geometry constants

    private let notchWidth:      CGFloat = 154
    private let notchHeight:     CGFloat = 24
    private let barHeight:       CGFloat = 112   // full expanded bar height
    private let triggerBand:     CGFloat = 44    // px below notch that wakes the bar
    private let triggerSideSlop: CGFloat = 40    // px either side of notch

    // MARK: - Properties

    private var panel: NSPanel!
    private var hostingController: NSHostingController<NotchBarView>!
    private var mouseMonitor: Any?
    private var localMonitor: Any?
    private var collapseTimer: Timer?

    private(set) var state: HUDState = .hidden {
        didSet { guard state != oldValue else { return }; applyState(state) }
    }

    let hudState = CurrentValueSubject<HUDState, Never>(.hidden)
    private let store: ClipboardStore

    // MARK: - Init

    init(store: ClipboardStore) {
        self.store = store
        super.init()
        guard isNotchScreen else { return }
        setupPanel()
        startMonitor()
    }

    deinit {
        if let m = mouseMonitor { NSEvent.removeMonitor(m) }
        if let m = localMonitor  { NSEvent.removeMonitor(m) }
    }

    // MARK: - Screen helpers

    private var isNotchScreen: Bool { (NSScreen.main?.safeAreaInsets.top ?? 0) > 0 }
    private var sw: CGFloat { NSScreen.main?.frame.width  ?? 1440 }
    private var sh: CGFloat { NSScreen.main?.frame.height ?? 900  }

    // MARK: - Frames

    /// Tiny sliver parked at top-center (invisible, just a hit-test surface).
    private var hiddenFrame: CGRect {
        CGRect(x: (sw - notchWidth) / 2,
               y: sh - notchHeight,
               width: notchWidth,
               height: notchHeight)
    }

    /// Full-width bar flush with the top of the screen.
    private var expandedFrame: CGRect {
        CGRect(x: 0, y: sh - barHeight, width: sw, height: barHeight)
    }

    /// Proximity trigger: tight horizontal band near the notch only.
    private var triggerRect: CGRect {
        CGRect(x: (sw - notchWidth) / 2 - triggerSideSlop,
               y: sh - notchHeight - triggerBand,
               width: notchWidth + triggerSideSlop * 2,
               height: notchHeight + triggerBand)
    }

    // MARK: - Panel setup

    private func setupPanel() {
        panel = NSPanel(
            contentRect: hiddenFrame,
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        panel.backgroundColor        = .clear
        panel.isOpaque               = false
        panel.hasShadow              = false
        panel.level                  = .statusBar + 1
        panel.collectionBehavior     = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.ignoresMouseEvents     = true   // passes through until expanded
        panel.alphaValue             = 0
        panel.isFloatingPanel        = true
        panel.becomesKeyOnlyIfNeeded = true

        let barView = NotchBarView(store: store, statePublisher: hudState) { [weak self] in
            self?.scheduleCollapse(after: 0)
        }

        hostingController = NSHostingController(rootView: barView)
        hostingController.sizingOptions = []   // we own the frame — no resize requests

        guard let contentView = panel.contentView else { return }
        let hv = hostingController.view
        hv.translatesAutoresizingMaskIntoConstraints = false
        hv.wantsLayer = true
        hv.layer?.backgroundColor = .clear
        contentView.addSubview(hv)

        NSLayoutConstraint.activate([
            hv.topAnchor.constraint(equalTo: contentView.topAnchor),
            hv.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            hv.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hv.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])

        panel.orderFrontRegardless()
    }

    // MARK: - State machine

    private func applyState(_ s: HUDState) {
        hudState.send(s)
        switch s {
        case .hidden:
            animate(to: hiddenFrame, alpha: 0) { self.panel.ignoresMouseEvents = true }
        case .expanded:
            panel.ignoresMouseEvents = false
            animate(to: expandedFrame, alpha: 1)
        case .collapsed:
            break
        }
    }

    /// Spring-feel animation using a custom cubic bezier.
    private func animate(to frame: CGRect, alpha: CGFloat, completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration                = 0.42
            ctx.timingFunction          = CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1)
            ctx.allowsImplicitAnimation = true
            panel.animator().setFrame(frame, display: true)
            panel.animator().alphaValue = alpha
        } completionHandler: { completion?() }
    }

    // MARK: - Mouse monitoring

    private func startMonitor() {
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            self?.handleMove()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] e in
            self?.handleMove(); return e
        }
    }

    private func handleMove() {
        let c = NSEvent.mouseLocation

        switch state {
        case .expanded:
            // Stay open while cursor is inside the bar + a small grace border.
            let stayZone = expandedFrame.insetBy(dx: 0, dy: -10)
            if stayZone.contains(c) {
                collapseTimer?.invalidate()
                collapseTimer = nil
            } else {
                scheduleCollapse(after: 0.35)
            }

        case .hidden:
            if triggerRect.contains(c) {
                collapseTimer?.invalidate()
                collapseTimer = nil
                // 100 ms debounce — ignore quick pass-overs.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { [weak self] in
                    guard let self else { return }
                    if self.triggerRect.contains(NSEvent.mouseLocation) {
                        self.state = .expanded
                    }
                }
            }
        case .collapsed:
            break
        }
    }

    private func scheduleCollapse(after delay: TimeInterval) {
        collapseTimer?.invalidate()
        collapseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.state = .hidden
            self?.collapseTimer = nil
        }
    }

    func collapse() { state = .hidden }
}


import AppKit
import Combine

/// Responsible **only** for watching NSPasteboard.
/// Publishes new plain-text strings via `newItem`; everything else is the store's job.
final class ClipboardManager {

    // Downstream subscribers (ClipboardStore) receive new text strings here.
    let newItem = PassthroughSubject<String, Never>()

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?

    init() {
        // Snapshot the current changeCount so we don't emit stale content on launch.
        lastChangeCount = pasteboard.changeCount
    }

    // MARK: - Lifecycle

    func start() {
        // RunLoop.main ensures the timer fires even during event tracking (e.g. while a menu is open).
        timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private

    private func poll() {
        let count = pasteboard.changeCount
        guard count != lastChangeCount else { return }
        lastChangeCount = count

        // MVP: plain text only. Extend here for RTF/images/files in the future.
        if let text = pasteboard.string(forType: .string), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            newItem.send(text)
        }
    }
}

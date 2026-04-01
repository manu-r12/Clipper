import AppKit
import Combine

/// Owns the persistent clipboard history array.
/// Handles deduplication, pinning, capacity limits, and UserDefaults persistence.
@MainActor
final class ClipboardStore: ObservableObject {

    @Published private(set) var items: [ClipboardItem] = []

    private let maxItems = 100
    private let persistenceKey = "clipboard_history_v1"
    private let manager = ClipboardManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        load()
        manager.newItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in self?.append(text) }
            .store(in: &cancellables)
        manager.start()
    }

    deinit { manager.stop() }

    // MARK: - Public API

    /// Copy `item`'s content to the pasteboard (does NOT add to history —
    /// the polling loop will detect the change; deduplication handles the rest).
    func copyToPasteboard(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.content, forType: .string)
    }

    func togglePin(_ item: ClipboardItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isPinned.toggle()
        save()
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func clearUnpinned() {
        items.removeAll { !$0.isPinned }
        save()
    }

    // MARK: - Private

    private func append(_ text: String) {
        // Deduplicate against the most recent non-pinned entry.
        let unpinned = items.filter { !$0.isPinned }
        if unpinned.first?.content == text { return }

        // Also skip if this exact text already exists anywhere (move to top instead).
        if let existing = items.firstIndex(where: { $0.content == text && !$0.isPinned }) {
            var item = items.remove(at: existing)
            item = ClipboardItem(content: item.content, date: .now, isPinned: item.isPinned)
            // Insert after pinned items.
            let insertAt = items.firstIndex(where: { !$0.isPinned }) ?? items.endIndex
            items.insert(item, at: insertAt)
        } else {
            let new = ClipboardItem(content: text)
            let insertAt = items.firstIndex(where: { !$0.isPinned }) ?? items.endIndex
            items.insert(new, at: insertAt)
        }

        // Trim to cap — never trim pinned items.
        let unpinnedItems = items.filter { !$0.isPinned }
        if unpinnedItems.count > maxItems {
            let toRemove = unpinnedItems.count - maxItems
            var removed = 0
            items.removeAll { item in
                guard !item.isPinned, removed < toRemove else { return false }
                removed += 1
                return true
            }
        }

        save()
    }

    // MARK: - Persistence (lightweight JSON via UserDefaults)

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: persistenceKey),
            let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data)
        else { return }
        items = decoded
    }
}

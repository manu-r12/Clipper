import SwiftUI
import Combine

/// Thin UI-logic layer sitting between ClipboardStore and ContentView.
/// Owns search state, keyboard-selection state, and copy-feedback state.
@MainActor
final class ClipboardViewModel: ObservableObject {

    // MARK: - Published state

    @Published var searchQuery: String = ""
    @Published var selectedIndex: Int = 0
    @Published var copiedID: UUID? = nil

    // MARK: - Dependencies

    let store: ClipboardStore

    // MARK: - Derived

    /// Filtered + ordered list the UI binds to.
    /// Pinned items always appear first, then chronological.
    var displayItems: [ClipboardItem] {
        let all = store.items
        guard !searchQuery.isEmpty else { return all }
        return all.filter { $0.content.localizedCaseInsensitiveContains(searchQuery) }
    }

    private var cancellables = Set<AnyCancellable>()

    init(store: ClipboardStore) {
        self.store = store

        // Reset keyboard selection whenever the list changes.
        store.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.selectedIndex = 0 }
            .store(in: &cancellables)

        $searchQuery
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.selectedIndex = 0 }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func copy(_ item: ClipboardItem) {
        store.copyToPasteboard(item)
        showCopiedFeedback(for: item.id)
    }

    func copySelected() {
        guard displayItems.indices.contains(selectedIndex) else { return }
        copy(displayItems[selectedIndex])
    }

    func moveUp() {
        if selectedIndex > 0 { selectedIndex -= 1 }
    }

    func moveDown() {
        if selectedIndex < displayItems.count - 1 { selectedIndex += 1 }
    }

    // MARK: - Private

    private func showCopiedFeedback(for id: UUID) {
        withAnimation(.easeInOut(duration: 0.15)) { copiedID = id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            withAnimation(.easeInOut(duration: 0.2)) {
                if self?.copiedID == id { self?.copiedID = nil }
            }
        }
    }
}

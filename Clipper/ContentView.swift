import SwiftUI

// MARK: - Root view (lives inside the NSPopover)

struct ContentView: View {
    @ObservedObject var vm: ClipboardViewModel
    /// Called by keyboard shortcut / Escape to close the popover.
    var onClose: () -> Void = {}

    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchHeader
            Divider().opacity(0.5)
            itemList
            Divider().opacity(0.5)
            footer
        }
        .frame(width: 420, height: 520)
        .background(
            // Frosted glass: use the window's blending where available.
            VisualEffectView(material: .menu, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
        // Auto-focus the search field whenever this view appears.
        .onAppear { searchFocused = true }
        // Keyboard routing: arrows + enter + escape.
        .onKeyPress(.upArrow)   { vm.moveUp();       return .handled }
        .onKeyPress(.downArrow) { vm.moveDown();      return .handled }
        .onKeyPress(.return)    { vm.copySelected();  onClose(); return .handled }
        .onKeyPress(.escape)    { onClose();          return .handled }
    }

    // MARK: - Search header (Raycast-style)

    private var searchHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.on.clipboard")
                .foregroundStyle(.secondary)
                .font(.system(size: 14, weight: .medium))

            TextField("Search clipboard history…", text: $vm.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($searchFocused)

            if !vm.searchQuery.isEmpty {
                Button {
                    vm.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - Item list

    private var itemList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if vm.displayItems.isEmpty {
                        emptyState
                    } else {
                        // Pinned section
                        let pinned = vm.displayItems.filter { $0.isPinned }
                        if !pinned.isEmpty {
                            sectionLabel("Pinned")
                            ForEach(pinned) { item in
                                itemRow(for: item)
                            }
                            Divider().padding(.horizontal, 12).opacity(0.4)
                        }

                        // Recent section
                        let recent = vm.displayItems.filter { !$0.isPinned }
                        if !recent.isEmpty {
                            if !pinned.isEmpty { sectionLabel("Recent") }
                            ForEach(recent) { item in
                                itemRow(for: item)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            // Keep keyboard-selected row visible.
            .onChange(of: vm.selectedIndex) { _, idx in
                let items = vm.displayItems
                guard items.indices.contains(idx) else { return }
                withAnimation(.easeInOut(duration: 0.15)) {
                    proxy.scrollTo(items[idx].id, anchor: .center)
                }
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func itemRow(for item: ClipboardItem) -> some View {
        let isSelected = vm.displayItems.firstIndex(where: { $0.id == item.id }) == vm.selectedIndex
        let isCopied   = vm.copiedID == item.id

        ClipboardRowView(
            item: item,
            isSelected: isSelected,
            isCopied: isCopied,
            onTap: {
                if let idx = vm.displayItems.firstIndex(where: { $0.id == item.id }) {
                    vm.selectedIndex = idx
                }
                vm.copy(item)
                onClose()
            },
            onPin:    { vm.store.togglePin(item) },
            onDelete: { vm.store.delete(item) }
        )
        .id(item.id)
    }

    // MARK: - Section label

    private func sectionLabel(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.8)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: vm.searchQuery.isEmpty ? "clipboard" : "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.quaternary)
            Text(vm.searchQuery.isEmpty ? "Nothing copied yet" : "No results")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 16) {
            Text("\(vm.store.items.count) items")
                .font(.system(size: 11))
                .foregroundStyle(.quaternary)

            Spacer()

            // Keyboard hints
            keyboardHint("↑↓", label: "navigate")
            keyboardHint("↩", label: "copy")

            Divider().frame(height: 12)

            Button("Clear All") {
                vm.store.clearUnpinned()
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
            .foregroundStyle(.red.opacity(0.7))
            .disabled(vm.store.items.filter { !$0.isPinned }.isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func keyboardHint(_ key: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(4)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.quaternary)
        }
    }
}

// MARK: - Individual row component

struct ClipboardRowView: View {
    let item: ClipboardItem
    let isSelected: Bool
    let isCopied: Bool
    let onTap: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(item.preview)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .foregroundStyle(isSelected ? .primary : .primary)

                Text(item.relativeTime)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right-side indicators
            HStack(spacing: 6) {
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange.opacity(0.8))
                }

                if isCopied {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                } else if isHovered || isSelected {
                    Text("copy")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(4)
                        .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button(item.isPinned ? "Unpin" : "Pin") { onPin() }
            Divider()
            Button("Copy") { onTap() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .animation(.easeInOut(duration: 0.12), value: isSelected)
        .animation(.spring(response: 0.25), value: isCopied)
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.accentColor.opacity(0.15))
                .padding(.horizontal, 6)
        } else if isHovered {
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.primary.opacity(0.05))
                .padding(.horizontal, 6)
        }
    }
}

// MARK: - NSVisualEffectView wrapper for frosted glass background

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

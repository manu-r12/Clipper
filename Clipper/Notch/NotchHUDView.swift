import SwiftUI
import Combine

// MARK: - Root HUD view

/// The SwiftUI view hosted inside the borderless notch window.
/// Morphs between a tiny pill and a rich clipboard card based on HUDState.
struct NotchHUDView: View {

    @ObservedObject private var storeWrapper: ClipboardStoreWrapper
    let statePublisher: CurrentValueSubject<HUDState, Never>
    var onDismiss: () -> Void

    @State private var currentState: HUDState = .hidden
    @State private var copiedID: UUID? = nil

    // Only show last 4 items in the HUD
    private var recentItems: [ClipboardItem] {
        Array(storeWrapper.store.items.prefix(4))
    }

    init(store: ClipboardStore,
         statePublisher: CurrentValueSubject<HUDState, Never>,
         onDismiss: @escaping () -> Void) {
        self.storeWrapper   = ClipboardStoreWrapper(store: store)
        self.statePublisher = statePublisher
        self.onDismiss      = onDismiss
    }

    var body: some View {
        ZStack {
            // Background morphs: pill → rounded card
            background

            if currentState == .expanded {
                expandedContent
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal:   .opacity
                        )
                    )
            } else {
                collapsedPill
                    .transition(.opacity)
            }
        }
        .onReceive(statePublisher) { newState in
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                currentState = newState
            }
        }
    }

    // MARK: - Background

    private var background: some View {
        RoundedRectangle(cornerRadius: currentState == .expanded ? 20 : 50)
            .fill(.black.opacity(0.88))
            .overlay(
                RoundedRectangle(cornerRadius: currentState == .expanded ? 20 : 50)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.18), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: .black.opacity(0.6), radius: 24, x: 0, y: 8)
            .animation(.spring(response: 0.38, dampingFraction: 0.72), value: currentState)
    }

    // MARK: - Collapsed pill

    private var collapsedPill: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(.white.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .scaleEffect(currentState == .collapsed ? 1 : 0.3)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.6)
                        .delay(Double(i) * 0.05),
                        value: currentState
                    )
            }
        }
    }

    // MARK: - Expanded card

    private var expandedContent: some View {
        VStack(spacing: 0) {
            hudHeader
            Divider()
                .background(.white.opacity(0.08))
                .padding(.horizontal, 12)

            if recentItems.isEmpty {
                emptyState
            } else {
                itemsStack
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Header

    private var hudHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            Text("Clipboard")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(0.3)

            Spacer()

            Text("\(recentItems.count) recent")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Items

    private var itemsStack: some View {
        VStack(spacing: 1) {
            ForEach(Array(recentItems.enumerated()), id: \.element.id) { index, item in
                HUDItemRow(
                    item: item,
                    isCopied: copiedID == item.id,
                    delay: Double(index) * 0.04
                ) {
                    copyItem(item)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "clipboard")
                .font(.system(size: 22))
                .foregroundStyle(.white.opacity(0.15))
            Text("Nothing copied yet")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.25))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func copyItem(_ item: ClipboardItem) {
        storeWrapper.store.copyToPasteboard(item)

        withAnimation(.spring(response: 0.2)) { copiedID = item.id }

        // Brief feedback, then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation { copiedID = nil }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onDismiss()
            }
        }
    }
}

// MARK: - Individual HUD row

struct HUDItemRow: View {
    let item: ClipboardItem
    let isCopied: Bool
    let delay: Double
    let onTap: () -> Void

    @State private var isHovered = false
    @State private var appeared  = false

    var body: some View {
        HStack(spacing: 10) {
            // Content type icon
            Image(systemName: contentIcon)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.3))
                .frame(width: 14)

            // Text preview
            Text(item.preview)
                .font(.system(size: 12, design: .default))
                .foregroundStyle(.white.opacity(isCopied ? 0.5 : 0.85))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Right side: time or copied check
            if isCopied {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text(item.relativeTime)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.2))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture(perform: onTap)
        .onHover { isHovered = $0 }
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(
                .spring(response: 0.35, dampingFraction: 0.7)
                .delay(delay)
            ) { appeared = true }
        }
        .onDisappear { appeared = false }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.spring(response: 0.2), value: isCopied)
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isHovered {
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.1))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.04))
        }
    }

    /// Guess a content-type icon from the text.
    private var contentIcon: String {
        let t = item.content
        if t.hasPrefix("http://") || t.hasPrefix("https://") { return "link" }
        if t.contains("@") && t.contains(".")                { return "envelope" }
        if t.filter({ $0.isNumber }).count > t.count / 2      { return "number" }
        return "text.alignleft"
    }
}

// MARK: - ObservableObject wrapper for ClipboardStore

/// Thin wrapper so NotchHUDView can observe ClipboardStore reactively.
final class ClipboardStoreWrapper: ObservableObject {
    let store: ClipboardStore
    private var cancellable: AnyCancellable?

    init(store: ClipboardStore) {
        self.store = store
        // Propagate store changes → trigger SwiftUI re-render
        cancellable = store.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
    }
}

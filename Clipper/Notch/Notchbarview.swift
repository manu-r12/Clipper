//
//  Notchbarview.swift
//  Clipper
//
//  Created by Manu on 2026-04-01.
//

import Foundation
import SwiftUI
import Combine

// MARK: - View

struct NotchBarView: View {

    @ObservedObject private var wrapper: StoreWrapper
    var statePublisher: CurrentValueSubject<HUDState, Never>
    var onDismiss: () -> Void

    @State private var query: String = ""
    @State private var visible: Bool = false
    @State private var copiedID: UUID? = nil
    @FocusState private var searchFocused: Bool

    private var clips: [ClipboardItem] {
        let base = wrapper.store.items
        if query.isEmpty { return Array(base.prefix(3)) }
        return Array(base.filter {
            $0.content.localizedCaseInsensitiveContains(query)
        }.prefix(3))
    }

    init(store: ClipboardStore,
         statePublisher: CurrentValueSubject<HUDState, Never>,
         onDismiss: @escaping () -> Void) {
        self.wrapper        = StoreWrapper(store: store)
        self.statePublisher = statePublisher
        self.onDismiss      = onDismiss
    }

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            ZStack(alignment: .bottom) {
                barBackground

                if visible {
                    HStack(spacing: 0) {
                        searchSection
                        divider
                        clipsSection
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .frame(maxWidth: 680, alignment: .top)
            .padding(.top, 16)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onReceive(statePublisher) { s in
            withAnimation(.easeInOut(duration: 0.22).delay(s == .expanded ? 0.18 : 0)) {
                visible = (s == .expanded)
            }
            if s == .expanded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                    searchFocused = true
                }
            } else {
                query = ""
                searchFocused = false
            }
        }
    }

    // MARK: - Background

    private var barBackground: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.clear)
                    .background(
                        VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                    )

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.82),
                                Color.black.opacity(0.75)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.0), .white.opacity(0.08)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 0.5)
                }
            }
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 8)
        }
    }

    // MARK: - Search section

    private var searchSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))

            TextField("Search clipboard…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundStyle(.white)
                .tint(.white)
                .focused($searchFocused)

            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.3))
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
            }
        }
        .frame(width: 220, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(width: 1, height: 50)
            .padding(.horizontal, 20)
    }

    // MARK: - Clips section

    private var clipsSection: some View {
        HStack(spacing: 12) {
            if clips.isEmpty {
                Text(query.isEmpty ? "Nothing copied yet" : "No matches")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.25))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(Array(clips.enumerated()), id: \.element.id) { idx, item in
                    clipPill(item: item, index: idx)

                    if idx < clips.count - 1 {
                        Rectangle()
                            .fill(.white.opacity(0.06))
                            .frame(width: 1, height: 36)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Clip pill

    @ViewBuilder
    private func clipPill(item: ClipboardItem, index: Int) -> some View {
        let isCopied = copiedID == item.id

        Button {
            copy(item)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: iconFor(item))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 14)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.preview)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(isCopied ? 0.4 : 0.85))
                        .lineLimit(1)
                        .frame(maxWidth: 180, alignment: .leading)

                    Text(item.relativeTime)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.2))
                }

                if isCopied {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.green.opacity(0.9))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isCopied ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                isCopied ? Color.green.opacity(0.3) : Color.white.opacity(0.06),
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .buttonStyle(HoverButtonStyle())
        .animation(.spring(response: 0.2), value: isCopied)
        .scaleEffect(visible ? 1 : 0.88)
        .opacity(visible ? 1 : 0)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.7)
            .delay(0.1 + Double(index) * 0.06),
            value: visible
        )
    }

    // MARK: - Helpers

    private func copy(_ item: ClipboardItem) {
        wrapper.store.copyToPasteboard(item)
        withAnimation(.spring(response: 0.2)) { copiedID = item.id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { if copiedID == item.id { copiedID = nil } }
        }
    }

    private func iconFor(_ item: ClipboardItem) -> String {
        let t = item.content
        if t.hasPrefix("http://") || t.hasPrefix("https://") { return "link" }
        if t.contains("@") && t.contains(".")               { return "envelope" }
        if t.filter({ $0.isNumber }).count > t.count / 2    { return "number" }
        return "text.alignleft"
    }
}

// MARK: - HoverButtonStyle

struct HoverButtonStyle: ButtonStyle {
    @State private var hovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(hovered ? Color.white.opacity(0.07) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .onHover { hovered = $0 }
            .animation(.easeInOut(duration: 0.12), value: hovered)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - VisualEffectBlur

struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material     = material
        v.blendingMode = blendingMode
        v.state        = .active
        return v
    }
    func updateNSView(_ v: NSVisualEffectView, context: Context) {}
}

// MARK: - UnevenRoundedRectangle

struct UnevenRoundedRectangle: Shape {
    var topLeadingRadius:     CGFloat
    var bottomLeadingRadius:  CGFloat
    var bottomTrailingRadius: CGFloat
    var topTrailingRadius:    CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tl = topLeadingRadius
        let tr = topTrailingRadius
        let bl = bottomLeadingRadius
        let br = bottomTrailingRadius

        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
                    radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
                    radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
                    radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
                    radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}

// MARK: - StoreWrapper

final class StoreWrapper: ObservableObject {
    let store: ClipboardStore
    private var cancellable: AnyCancellable?

    init(store: ClipboardStore) {
        self.store = store
        cancellable = store.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
    }
}

//
//  ViewSizePreferenceKey.swift
//  Clipper
//
//  Created by Manu on 2026-04-19.
//


import SwiftUI

private struct ViewSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    func onMeasuredSize(_ action: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: ViewSizePreferenceKey.self, value: proxy.size)
            }
        )
        .onPreferenceChange(ViewSizePreferenceKey.self, perform: action)
    }
}

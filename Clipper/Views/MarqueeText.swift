import SwiftUI
import AppKit

private struct MarqueeSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct MarqueeText: View {
    @Binding var text: String
    var font: Font = .body
    var nsFont: NSFont.TextStyle = .body
    var textColor: Color = .primary
    var minDuration: Double = 3.0
    var frameWidth: CGFloat = 200

    @State private var animate = false
    @State private var textSize: CGSize = .zero
    @State private var offset: CGFloat = 0

    init(_ text: Binding<String>, font: Font = .body, nsFont: NSFont.TextStyle = .body, textColor: Color = .primary, minDuration: Double = 3.0, frameWidth: CGFloat = 200) {
        _text = text
        self.font = font
        self.nsFont = nsFont
        self.textColor = textColor
        self.minDuration = minDuration
        self.frameWidth = frameWidth
    }

    private var needsScrolling: Bool { textSize.width > frameWidth }

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .leading) {
                HStack(spacing: 20) {
                    Text(text)
                    Text(text).opacity(needsScrolling ? 1 : 0)
                }
                .id(text)
                .font(font)
                .foregroundColor(textColor)
                .fixedSize(horizontal: true, vertical: false)
                .offset(x: animate ? offset : 0)
                .animation(
                    animate
                        ? .linear(duration: Double(textSize.width / 30)).delay(minDuration).repeatForever(autoreverses: false)
                        : .none,
                    value: animate
                )
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: MarqueeSizeKey.self, value: geo.size)
                    }
                )
                .onPreferenceChange(MarqueeSizeKey.self) { size in
                    let fontHeight = NSFont.preferredFont(forTextStyle: nsFont).pointSize
                    textSize = CGSize(width: size.width / 2, height: fontHeight)
                    startScroll()
                }
                .onChange(of: text) { _, _ in startScroll() }
            }
            .frame(width: frameWidth, alignment: .leading)
            .clipped()
        }
        .frame(height: max(textSize.height * 1.3, 14))
    }

    private func startScroll() {
        animate = false
        offset = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            if needsScrolling {
                animate = true
                offset = -(textSize.width + 20)
            }
        }
    }
}

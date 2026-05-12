import SwiftUI
import Darwin

private struct AlbumArtFlipModifier: ViewModifier {
    let angle: Double

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(angle),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                anchorZ: 0,
                perspective: 0.5
            )
            // Counter-rotate so the image never appears mirrored when past 90°.
            .scaleEffect(x: cosineSign(for: angle), y: 1)
    }

    private func cosineSign(for degrees: Double) -> CGFloat {
        let c = Darwin.cos(degrees * .pi / 180)
        if c > 0.001 { return 1 }
        if c < -0.001 { return -1 }
        return degrees.truncatingRemainder(dividingBy: 360) >= 0 ? -1 : 1
    }
}

extension View {
    func albumArtFlip(angle: Double) -> some View {
        modifier(AlbumArtFlipModifier(angle: angle))
    }
}

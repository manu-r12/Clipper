import SwiftUI
import AppKit

extension Color {
    /// Boosts the brightness of the color so it's never darker than `factor` (0–1).
    /// Matches Atoll's `ensureMinimumBrightness(factor:)` extension.
    func ensureMinimumBrightness(factor: CGFloat = 0.6) -> Color {
        guard let rgb = NSColor(self).usingColorSpace(.sRGB) else { return self }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        guard b < factor else { return self }
        return Color(NSColor(hue: h, saturation: s, brightness: factor, alpha: a))
    }
}

import AppKit
import CoreImage

extension NSImage {
    var averageColor: NSColor {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return .gray }
        let ci = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ci.clampedToExtent(),
            kCIInputExtentKey: CIVector(cgRect: ci.extent)
        ]), let output = filter.outputImage else { return .gray }
        var pixel = [UInt8](repeating: 0, count: 4)
        let ctx = CIContext()
        let bounds = CGRect(x: 0, y: 0, width: 1, height: 1)
        let cs = CGColorSpaceCreateDeviceRGB()
        ctx.render(output, toBitmap: &pixel, rowBytes: 4, bounds: bounds, format: .RGBA8, colorSpace: cs)
        let r = CGFloat(pixel[0]) / 255
        let g = CGFloat(pixel[1]) / 255
        let b = CGFloat(pixel[2]) / 255
        return NSColor(calibratedRed: r, green: g, blue: b, alpha: 1)
    }
}

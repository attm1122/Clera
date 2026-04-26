import UIKit
import CoreGraphics

/// Generates binary masks and cropped regions for face zones.
enum ZoneMaskGenerator {

    /// Creates a grayscale mask from a zone polygon path.
    static func createMask(for zonePath: [CGPoint], imageSize: CGSize) -> CGImage? {
        guard !zonePath.isEmpty else { return nil }

        let width = Int(imageSize.width)
        let height = Int(imageSize.height)
        var maskBytes = [UInt8](repeating: 0, count: width * height)

        // Simple scanline fill
        let minY = max(0, Int(zonePath.map(\.y).min()! * imageSize.height))
        let maxY = min(height - 1, Int(zonePath.map(\.y).max()! * imageSize.height))

        for y in minY...maxY {
            let rowY = CGFloat(y) / imageSize.height
            let intersections = findIntersections(atY: rowY, path: zonePath)
            guard intersections.count >= 2 else { continue }

            let sorted = intersections.sorted()
            for i in stride(from: 0, to: sorted.count - 1, by: 2) {
                let x1 = max(0, Int(sorted[i] * imageSize.width))
                let x2 = min(width - 1, Int(sorted[i + 1] * imageSize.width))
                for x in x1...x2 {
                    maskBytes[y * width + x] = 255
                }
            }
        }

        guard let provider = CGDataProvider(data: Data(maskBytes) as CFData) else { return nil }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }

    /// Crops a zone region from an image using the zone polygon as a bounding mask.
    static func cropZone(from image: UIImage, zonePath: [CGPoint]) -> UIImage? {
        guard !zonePath.isEmpty else { return nil }

        let xs = zonePath.map(\.x)
        let ys = zonePath.map(\.y)
        let minX = max(0, xs.min()!)
        let maxX = min(1, xs.max()!)
        let minY = max(0, ys.min()!)
        let maxY = min(1, ys.max()!)

        let imageSize = image.size
        let cropRect = CGRect(
            x: minX * imageSize.width,
            y: (1 - maxY) * imageSize.height,  // Flip Y for UIKit
            width: (maxX - minX) * imageSize.width,
            height: (maxY - minY) * imageSize.height
        )

        guard let cgImage = image.cgImage else { return nil }
        guard let cropped = cgImage.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Private

    private static func findIntersections(atY y: CGFloat, path: [CGPoint]) -> [CGFloat] {
        var intersections: [CGFloat] = []
        let n = path.count
        for i in 0..<n {
            let p1 = path[i]
            let p2 = path[(i + 1) % n]
            if (p1.y <= y && p2.y > y) || (p2.y <= y && p1.y > y) {
                let t = (y - p1.y) / (p2.y - p1.y)
                let x = p1.x + t * (p2.x - p1.x)
                intersections.append(x)
            }
        }
        return intersections
    }
}

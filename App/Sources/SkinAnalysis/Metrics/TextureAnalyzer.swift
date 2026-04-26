import UIKit
import CoreGraphics

/// Analyses surface texture using Laplacian variance on grayscale zone pixels.
struct TextureAnalyzer: SkinMetricAnalyzer {
    let metricKey: SkinMetricKey = .texture

    func analyze(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> SkinMetricScore {
        guard let score = computeTextureScore(image: image, skinMask: skinMask, zoneMask: zoneMask) else {
            return SkinMetricScore(score: 0, confidence: .low, trend: .insufficientData, reason: "Could not analyse texture in this zone.")
        }

        let reason = score > 55
            ? "Surface texture appears slightly rougher than typical."
            : score > 35
                ? "Texture looks moderate."
                : "Surface texture appears smoother than typical."

        return SkinMetricScore(score: score, confidence: .medium, trend: .insufficientData, reason: reason)
    }

    private func computeTextureScore(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> Int? {
        guard let cgImage = image.cgImage,
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow

        var laplacianSum: Double = 0
        var laplacianSqSum: Double = 0
        var count = 0

        for y in stride(from: 1, to: height - 1, by: 2) {
            for x in stride(from: 1, to: width - 1, by: 2) {
                if !isInMasks(x: x, y: y, width: width, height: height, skinMask: skinMask, zoneMask: zoneMask) {
                    continue
                }

                let centerOffset = y * bytesPerRow + x * bytesPerPixel
                let center = Double(ptr[centerOffset])
                let top = Double(ptr[(y - 1) * bytesPerRow + x * bytesPerPixel])
                let bottom = Double(ptr[(y + 1) * bytesPerRow + x * bytesPerPixel])
                let left = Double(ptr[y * bytesPerRow + (x - 1) * bytesPerPixel])
                let right = Double(ptr[y * bytesPerRow + (x + 1) * bytesPerPixel])

                let laplacian = abs(4 * center - top - bottom - left - right)
                laplacianSum += laplacian
                laplacianSqSum += laplacian * laplacian
                count += 1
            }
        }

        guard count > 10 else { return nil }
        let mean = laplacianSum / Double(count)
        let variance = (laplacianSqSum / Double(count)) - (mean * mean)
        let normalizedVariance = sqrt(max(variance, 0)) / 500.0
        let score = Int(normalizedVariance * 100)
        return max(0, min(100, score))
    }
}

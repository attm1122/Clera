import UIKit
import CoreGraphics

/// Detects small dark blob-like regions using adaptive thresholding.
struct SpotAnalyzer: SkinMetricAnalyzer {
    let metricKey: SkinMetricKey = .breakoutLikeSpots

    func analyze(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> SkinMetricScore {
        guard let score = computeSpotScore(image: image, skinMask: skinMask, zoneMask: zoneMask) else {
            return SkinMetricScore(score: 0, confidence: .low, trend: .insufficientData, reason: "Could not detect spot-like regions in this zone.")
        }

        let reason = score > 55
            ? "More small spot-like regions detected than typical."
            : score > 30
                ? "A few spot-like regions are visible."
                : "Fewer spot-like regions detected."

        return SkinMetricScore(score: score, confidence: .medium, trend: .insufficientData, reason: reason)
    }

    private func computeSpotScore(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> Int? {
        guard let cgImage = image.cgImage,
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow

        // Compute mean luminance in masked region
        var totalLum: Double = 0
        var pixelCount = 0

        for y in stride(from: 0, to: height, by: 4) {
            for x in stride(from: 0, to: width, by: 4) {
                if !isInMasks(x: x, y: y, width: width, height: height, skinMask: skinMask, zoneMask: zoneMask) {
                    continue
                }
                let offset = y * bytesPerRow + x * bytesPerPixel
                let lum = Double(ptr[offset]) * 0.299 + Double(ptr[offset + 1]) * 0.587 + Double(ptr[offset + 2]) * 0.114
                totalLum += lum
                pixelCount += 1
            }
        }

        guard pixelCount > 10 else { return nil }
        let meanLum = totalLum / Double(pixelCount)
        let threshold = meanLum * 0.55  // Darker than 55% of mean

        // Count dark blob pixels
        var darkPixelCount = 0

        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2) {
                if !isInMasks(x: x, y: y, width: width, height: height, skinMask: skinMask, zoneMask: zoneMask) {
                    continue
                }
                let offset = y * bytesPerRow + x * bytesPerPixel
                let lum = Double(ptr[offset]) * 0.299 + Double(ptr[offset + 1]) * 0.587 + Double(ptr[offset + 2]) * 0.114
                if lum < threshold {
                    darkPixelCount += 1
                }
            }
        }

        let darkRatio = Double(darkPixelCount) / Double(pixelCount)
        let score = Int(darkRatio * 500)  // Scale: 20% dark pixels = score 100
        return max(0, min(100, score))
    }
}

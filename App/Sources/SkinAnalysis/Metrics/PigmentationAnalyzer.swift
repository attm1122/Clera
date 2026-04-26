import UIKit
import CoreGraphics

/// Detects dark spots using luminance thresholding.
struct PigmentationAnalyzer: SkinMetricAnalyzer {
    let metricKey: SkinMetricKey = .pigmentation

    func analyze(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> SkinMetricScore {
        guard let score = computePigmentationScore(image: image, skinMask: skinMask, zoneMask: zoneMask) else {
            return SkinMetricScore(score: 0, confidence: .low, trend: .insufficientData, reason: "Could not analyse pigmentation in this zone.")
        }

        let reason = score > 55
            ? "Pigmentation appears slightly more noticeable."
            : score > 30
                ? "Pigmentation looks moderate."
                : "Pigmentation appears less noticeable."

        return SkinMetricScore(score: score, confidence: .medium, trend: .insufficientData, reason: reason)
    }

    private func computePigmentationScore(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> Int? {
        guard let cgImage = image.cgImage,
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow

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
        let darkThreshold = meanLum * 0.45

        var darkSpotCount = 0
        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2) {
                if !isInMasks(x: x, y: y, width: width, height: height, skinMask: skinMask, zoneMask: zoneMask) {
                    continue
                }
                let offset = y * bytesPerRow + x * bytesPerPixel
                let lum = Double(ptr[offset]) * 0.299 + Double(ptr[offset + 1]) * 0.587 + Double(ptr[offset + 2]) * 0.114
                if lum < darkThreshold {
                    darkSpotCount += 1
                }
            }
        }

        let darkRatio = Double(darkSpotCount) / Double(pixelCount)
        let score = Int(darkRatio * 400)
        return max(0, min(100, score))
    }
}

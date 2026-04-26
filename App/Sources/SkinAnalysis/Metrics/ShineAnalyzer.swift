import UIKit
import CoreGraphics

/// Detects specular highlights indicating oiliness/shine.
struct ShineAnalyzer: SkinMetricAnalyzer {
    let metricKey: SkinMetricKey = .shine

    func analyze(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> SkinMetricScore {
        guard let score = computeShineScore(image: image, skinMask: skinMask, zoneMask: zoneMask) else {
            return SkinMetricScore(score: 0, confidence: .low, trend: .insufficientData, reason: "Could not analyse shine in this zone.")
        }

        let reason = score > 55
            ? "More shiny regions detected, suggesting higher oiliness."
            : score > 30
                ? "Some shine is visible."
                : "Fewer shiny regions detected."

        return SkinMetricScore(score: score, confidence: .medium, trend: .insufficientData, reason: reason)
    }

    private func computeShineScore(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> Int? {
        guard let cgImage = image.cgImage,
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow

        var highlightCount = 0
        var pixelCount = 0

        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2) {
                if !isInMasks(x: x, y: y, width: width, height: height, skinMask: skinMask, zoneMask: zoneMask) {
                    continue
                }
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = Int(ptr[offset])
                let g = Int(ptr[offset + 1])
                let b = Int(ptr[offset + 2])

                // Specular highlight: very bright, low saturation
                let maxVal = max(r, max(g, b))
                let minVal = min(r, min(g, b))
                let saturation = maxVal - minVal

                if maxVal > 220 && saturation < 30 {
                    highlightCount += 1
                }
                pixelCount += 1
            }
        }

        guard pixelCount > 10 else { return nil }
        let ratio = Double(highlightCount) / Double(pixelCount)
        let score = Int(ratio * 2000)  // Scale: 5% highlights = score 100
        return max(0, min(100, score))
    }
}

import UIKit
import CoreGraphics

/// Analyses red/green ratio in skin-masked pixels to estimate redness.
struct RednessAnalyzer: SkinMetricAnalyzer {
    let metricKey: SkinMetricKey = .redness

    func analyze(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> SkinMetricScore {
        guard let score = computeRednessScore(image: image, skinMask: skinMask, zoneMask: zoneMask) else {
            return SkinMetricScore(score: 0, confidence: .low, trend: .insufficientData, reason: "Could not analyse redness in this zone.")
        }

        let reason = score > 55
            ? "More red-toned pixels detected than typical."
            : score > 35
                ? "Redness levels look moderate."
                : "Fewer red-toned pixels detected."

        return SkinMetricScore(score: score, confidence: .medium, trend: .insufficientData, reason: reason)
    }

    private func computeRednessScore(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> Int? {
        guard let cgImage = image.cgImage,
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow

        var totalRedness: Double = 0
        var sampleCount = 0

        for y in stride(from: 0, to: height, by: 4) {
            for x in stride(from: 0, to: width, by: 4) {
                if !isInMasks(x: x, y: y, width: width, height: height, skinMask: skinMask, zoneMask: zoneMask) {
                    continue
                }

                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = Double(ptr[offset])
                let g = Double(ptr[offset + 1])
                let b = Double(ptr[offset + 2])

                guard r + g + b > 30 else { continue }

                // Redness = R / (G + B) ratio, normalised
                let redness = r / (g + b + 1.0)
                totalRedness += redness
                sampleCount += 1
            }
        }

        guard sampleCount > 10 else { return nil }
        let avgRedness = totalRedness / Double(sampleCount)
        // Typical skin redness ratio ~0.6-1.2. Map to 0-100.
        let score = Int((avgRedness - 0.4) / 1.0 * 100)
        return max(0, min(100, score))
    }
}

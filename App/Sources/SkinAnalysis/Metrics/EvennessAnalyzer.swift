import UIKit
import CoreGraphics

/// Measures colour distribution uniformity across the zone.
struct EvennessAnalyzer: SkinMetricAnalyzer {
    let metricKey: SkinMetricKey = .evenness

    func analyze(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> SkinMetricScore {
        guard let score = computeEvennessScore(image: image, skinMask: skinMask, zoneMask: zoneMask) else {
            return SkinMetricScore(score: 0, confidence: .low, trend: .insufficientData, reason: "Could not analyse evenness in this zone.")
        }

        let reason = score > 60
            ? "Colour distribution is fairly uniform across the zone."
            : score > 35
                ? "Colour distribution looks moderately varied."
                : "Colour distribution shows more variation than typical."

        return SkinMetricScore(score: score, confidence: .medium, trend: .insufficientData, reason: reason)
    }

    private func computeEvennessScore(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> Int? {
        guard let cgImage = image.cgImage,
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow

        var rValues: [Double] = []
        var gValues: [Double] = []
        var bValues: [Double] = []

        for y in stride(from: 0, to: height, by: 4) {
            for x in stride(from: 0, to: width, by: 4) {
                if !isInMasks(x: x, y: y, width: width, height: height, skinMask: skinMask, zoneMask: zoneMask) {
                    continue
                }
                let offset = y * bytesPerRow + x * bytesPerPixel
                rValues.append(Double(ptr[offset]))
                gValues.append(Double(ptr[offset + 1]))
                bValues.append(Double(ptr[offset + 2]))
            }
        }

        guard rValues.count > 10 else { return nil }

        let rStd = standardDeviation(rValues)
        let gStd = standardDeviation(gValues)
        let bStd = standardDeviation(bValues)
        let avgStd = (rStd + gStd + bStd) / 3.0

        // Lower std dev = more even. Typical skin std ~15-40.
        // Map: std 5 -> score 100, std 50 -> score 0
        let score = Int(100 - (avgStd - 5) * 2.2)
        return max(0, min(100, score))
    }

    private func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
}

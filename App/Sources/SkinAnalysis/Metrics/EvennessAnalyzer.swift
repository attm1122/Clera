import UIKit
import CoreGraphics

/// Measures colour distribution uniformity across the zone.
struct EvennessAnalyzer: SkinMetricAnalyzer {
    let metricKey: SkinMetricKey = .evenness

    func analyze(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> SkinMetricScore {
        guard let sampler = PixelBufferSampler(image: image),
              let score = computeEvennessScore(sampler: sampler, skinMask: skinMask, zoneMask: zoneMask) else {
            return SkinMetricScore(score: 0, confidence: .low, trend: .insufficientData, reason: "Could not analyse evenness in this zone.")
        }

        let reason = score > 60
            ? "Colour distribution is fairly uniform across the zone."
            : score > 35
                ? "Colour distribution looks moderately varied."
                : "Colour distribution shows more variation than typical."

        return SkinMetricScore(score: score, confidence: .medium, trend: .insufficientData, reason: reason)
    }

    private func computeEvennessScore(sampler: PixelBufferSampler, skinMask: CGImage?, zoneMask: CGImage?) -> Int? {
        var rValues: [Double] = []
        var gValues: [Double] = []
        var bValues: [Double] = []

        sampler.enumerateMaskedPixels(step: 4, skinMask: skinMask, zoneMask: zoneMask) { offset in
            rValues.append(Double(sampler.ptr[offset]))
            gValues.append(Double(sampler.ptr[offset + 1]))
            bValues.append(Double(sampler.ptr[offset + 2]))
        }

        guard rValues.count > 10 else { return nil }

        let rStd = standardDeviation(rValues)
        let gStd = standardDeviation(gValues)
        let bStd = standardDeviation(bValues)
        let avgStd = (rStd + gStd + bStd) / 3.0

        let score = Int(100 - (avgStd - 5) * 2.2)
        return PixelBufferSampler.clampScore(score)
    }

    private func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
}

import UIKit
import CoreGraphics

/// Analyses red/green ratio in skin-masked pixels to estimate redness.
struct RednessAnalyzer: SkinMetricAnalyzer {
    let metricKey: SkinMetricKey = .redness

    func analyze(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> SkinMetricScore {
        guard let sampler = PixelBufferSampler(image: image),
              let score = computeRednessScore(sampler: sampler, skinMask: skinMask, zoneMask: zoneMask) else {
            return SkinMetricScore(score: 0, confidence: .low, trend: .insufficientData, reason: "Could not analyse redness in this zone.")
        }

        let reason = score > 55
            ? "More red-toned pixels detected than typical."
            : score > 35
                ? "Redness levels look moderate."
                : "Fewer red-toned pixels detected."

        return SkinMetricScore(score: score, confidence: .medium, trend: .insufficientData, reason: reason)
    }

    private func computeRednessScore(sampler: PixelBufferSampler, skinMask: CGImage?, zoneMask: CGImage?) -> Int? {
        var totalRedness: Double = 0
        var sampleCount = 0

        sampler.enumerateMaskedPixels(step: 4, skinMask: skinMask, zoneMask: zoneMask) { offset in
            let r = Double(sampler.ptr[offset])
            let g = Double(sampler.ptr[offset + 1])
            let b = Double(sampler.ptr[offset + 2])
            guard r + g + b > 30 else { return }
            totalRedness += r / (g + b + 1.0)
            sampleCount += 1
        }

        guard sampleCount > 10 else { return nil }
        let avgRedness = totalRedness / Double(sampleCount)
        let score = Int((avgRedness - 0.4) / 1.0 * 100)
        return PixelBufferSampler.clampScore(score)
    }
}

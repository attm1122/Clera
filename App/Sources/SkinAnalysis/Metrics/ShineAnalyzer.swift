import UIKit
import CoreGraphics

/// Detects specular highlights indicating oiliness/shine.
struct ShineAnalyzer: SkinMetricAnalyzer {
    let metricKey: SkinMetricKey = .shine

    func analyze(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> SkinMetricScore {
        guard let sampler = PixelBufferSampler(image: image),
              let score = computeShineScore(sampler: sampler, skinMask: skinMask, zoneMask: zoneMask) else {
            return SkinMetricScore(score: 0, confidence: .low, trend: .insufficientData, reason: "Could not analyse shine in this zone.")
        }

        let reason = score > 55
            ? "More shiny regions detected, suggesting higher oiliness."
            : score > 30
                ? "Some shine is visible."
                : "Fewer shiny regions detected."

        return SkinMetricScore(score: score, confidence: .medium, trend: .insufficientData, reason: reason)
    }

    private func computeShineScore(sampler: PixelBufferSampler, skinMask: CGImage?, zoneMask: CGImage?) -> Int? {
        var highlightCount = 0
        var pixelCount = 0

        sampler.enumerateMaskedPixels(step: 2, skinMask: skinMask, zoneMask: zoneMask) { offset in
            let r = Int(sampler.ptr[offset])
            let g = Int(sampler.ptr[offset + 1])
            let b = Int(sampler.ptr[offset + 2])
            let maxVal = max(r, max(g, b))
            let minVal = min(r, min(g, b))
            let saturation = maxVal - minVal

            if maxVal > 220 && saturation < 30 {
                highlightCount += 1
            }
            pixelCount += 1
        }

        guard pixelCount > 10 else { return nil }
        let ratio = Double(highlightCount) / Double(pixelCount)
        let score = Int(ratio * 2000)
        return PixelBufferSampler.clampScore(score)
    }
}

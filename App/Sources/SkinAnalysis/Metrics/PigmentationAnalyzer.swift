import UIKit
import CoreGraphics

/// Detects dark spots using luminance thresholding.
struct PigmentationAnalyzer: SkinMetricAnalyzer {
    let metricKey: SkinMetricKey = .pigmentation

    func analyze(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> SkinMetricScore {
        guard let sampler = PixelBufferSampler(image: image),
              let score = computePigmentationScore(sampler: sampler, skinMask: skinMask, zoneMask: zoneMask) else {
            return SkinMetricScore(score: 0, confidence: .low, trend: .insufficientData, reason: "Could not analyse pigmentation in this zone.")
        }

        let reason = score > 55
            ? "Pigmentation appears slightly more noticeable."
            : score > 30
                ? "Pigmentation looks moderate."
                : "Pigmentation appears less noticeable."

        return SkinMetricScore(score: score, confidence: .medium, trend: .insufficientData, reason: reason)
    }

    private func computePigmentationScore(sampler: PixelBufferSampler, skinMask: CGImage?, zoneMask: CGImage?) -> Int? {
        var totalLum: Double = 0
        var pixelCount = 0

        sampler.enumerateMaskedPixels(step: 4, skinMask: skinMask, zoneMask: zoneMask) { offset in
            totalLum += luminance(sampler.ptr, offset)
            pixelCount += 1
        }

        guard pixelCount > 10 else { return nil }
        let meanLum = totalLum / Double(pixelCount)
        let darkThreshold = meanLum * 0.45

        var darkSpotCount = 0
        sampler.enumerateMaskedPixels(step: 2, skinMask: skinMask, zoneMask: zoneMask) { offset in
            if luminance(sampler.ptr, offset) < darkThreshold {
                darkSpotCount += 1
            }
        }

        let darkRatio = Double(darkSpotCount) / Double(pixelCount)
        let score = Int(darkRatio * 400)
        return PixelBufferSampler.clampScore(score)
    }

    private func luminance(_ ptr: UnsafePointer<UInt8>, _ offset: Int) -> Double {
        Double(ptr[offset]) * 0.299 + Double(ptr[offset + 1]) * 0.587 + Double(ptr[offset + 2]) * 0.114
    }
}

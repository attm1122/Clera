import UIKit
import CoreGraphics

/// Detects small dark blob-like regions using adaptive thresholding.
struct SpotAnalyzer: SkinMetricAnalyzer {
    let metricKey: SkinMetricKey = .breakoutLikeSpots

    func analyze(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> SkinMetricScore {
        guard let sampler = PixelBufferSampler(image: image),
              let score = computeSpotScore(sampler: sampler, skinMask: skinMask, zoneMask: zoneMask) else {
            return SkinMetricScore(score: 0, confidence: .low, trend: .insufficientData, reason: "Could not detect spot-like regions in this zone.")
        }

        let reason = score > 55
            ? "More small spot-like regions detected than typical."
            : score > 30
                ? "A few spot-like regions are visible."
                : "Fewer spot-like regions detected."

        return SkinMetricScore(score: score, confidence: .medium, trend: .insufficientData, reason: reason)
    }

    private func computeSpotScore(sampler: PixelBufferSampler, skinMask: CGImage?, zoneMask: CGImage?) -> Int? {
        var totalLum: Double = 0
        var pixelCount = 0

        sampler.enumerateMaskedPixels(step: 4, skinMask: skinMask, zoneMask: zoneMask) { offset in
            totalLum += luminance(sampler.ptr, offset)
            pixelCount += 1
        }

        guard pixelCount > 10 else { return nil }
        let meanLum = totalLum / Double(pixelCount)
        let threshold = meanLum * 0.55

        var darkPixelCount = 0
        sampler.enumerateMaskedPixels(step: 2, skinMask: skinMask, zoneMask: zoneMask) { offset in
            if luminance(sampler.ptr, offset) < threshold {
                darkPixelCount += 1
            }
        }

        let darkRatio = Double(darkPixelCount) / Double(pixelCount)
        let score = Int(darkRatio * 500)
        return PixelBufferSampler.clampScore(score)
    }

    private func luminance(_ ptr: UnsafePointer<UInt8>, _ offset: Int) -> Double {
        Double(ptr[offset]) * 0.299 + Double(ptr[offset + 1]) * 0.587 + Double(ptr[offset + 2]) * 0.114
    }
}

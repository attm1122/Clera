import UIKit
import CoreGraphics

/// Detects flaky texture patterns consistent with dryness.
/// NOTE: This is the lowest-confidence metric. Dryness is extremely hard to detect from photos.
struct DrynessAnalyzer: SkinMetricAnalyzer {
    let metricKey: SkinMetricKey = .dryness

    func analyze(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> SkinMetricScore {
        guard let score = computeDrynessScore(image: image, skinMask: skinMask, zoneMask: zoneMask) else {
            return SkinMetricScore(
                score: 0,
                confidence: .low,
                trend: .insufficientData,
                reason: "Dryness detection requires more consistent lighting."
            )
        }

        let reason = score > 50
            ? "Surface patterns suggest slightly more dryness signal. Note: this metric has lower confidence."
            : "Surface patterns suggest less dryness signal. Note: this metric has lower confidence."

        return SkinMetricScore(score: score, confidence: .low, trend: .insufficientData, reason: reason)
    }

    private func computeDrynessScore(image: UIImage, skinMask: CGImage?, zoneMask: CGImage?) -> Int? {
        guard let cgImage = image.cgImage,
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow

        // Dry skin often shows as fine texture with high local variance
        // but lower overall contrast. We approximate by looking at
        // texture variance in mid-brightness regions.
        var textureSum: Double = 0
        var count = 0

        for y in stride(from: 2, to: height - 2, by: 4) {
            for x in stride(from: 2, to: width - 2, by: 4) {
                if !isInMasks(x: x, y: y, width: width, height: height, skinMask: skinMask, zoneMask: zoneMask) {
                    continue
                }

                let offset = y * bytesPerRow + x * bytesPerPixel
                let lum = Double(ptr[offset]) * 0.299 + Double(ptr[offset + 1]) * 0.587 + Double(ptr[offset + 2]) * 0.114

                // Focus on mid-brightness skin (not too dark, not shiny)
                guard lum > 80 && lum < 200 else { continue }

                let localVar = localVariance(at: (x, y), ptr: ptr, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel, width: width, height: height)
                textureSum += localVar
                count += 1
            }
        }

        guard count > 10 else { return nil }
        let avgTexture = textureSum / Double(count)
        // Higher fine texture variance may indicate dryness
        let score = Int(avgTexture / 3.0)
        return max(0, min(100, score))
    }

    private func localVariance(at point: (Int, Int), ptr: UnsafePointer<UInt8>, bytesPerRow: Int, bytesPerPixel: Int, width: Int, height: Int) -> Double {
        let (cx, cy) = point
        var values: [Double] = []
        for dy in -1...1 {
            for dx in -1...1 {
                let px = cx + dx
                let py = cy + dy
                guard px >= 0 && px < width && py >= 0 && py < height else { continue }
                let offset = py * bytesPerRow + px * bytesPerPixel
                let lum = Double(ptr[offset]) * 0.299 + Double(ptr[offset + 1]) * 0.587 + Double(ptr[offset + 2]) * 0.114
                values.append(lum)
            }
        }
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
}

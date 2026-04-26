import UIKit

/// Deterministic simulator skin analysis that produces realistic mock data
/// when Vision face detection is unavailable (iOS Simulator).
///
/// The results are based on the image's average color properties so that
/// different photos produce *different but deterministic* analyses.
/// This avoids the "every scan looks identical" problem of static sample data.
enum SimulatorSkinAnalyzer {

    static var isRunningOnSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// Generates a realistic skin analysis result for simulator testing.
    /// Uses image properties (brightness, saturation) to derive deterministic scores.
    static func analyze(
        scanId: UUID,
        userId: String,
        frontImage: UIImage
    ) -> SkinAnalysisResult {
        let imageProperties = analyzeImageProperties(frontImage)
        let quality = ScanQualityResult(
            accepted: true,
            lighting: .good,
            blur: .low,
            pose: .valid,
            distance: .valid,
            obstruction: .none,
            resolution: .valid,
            confidence: .medium,
            issues: ["Running in simulator mode — analysis is simulated for testing."]
        )

        let zones = SkinZone.allCases.map { zone in
            let metrics = generateMetrics(for: zone, imageProperties: imageProperties)
            let topInsight = generateInsight(for: zone, metrics: metrics)
            return SkinZoneAnalysis(
                zone: zone,
                metrics: metrics,
                topInsight: topInsight,
                confidence: .medium,
                maskPath: nil,
                croppedImageFileName: nil
            )
        }

        let summary = SkinAnalysisSummary(
            overallStatus: .stableWithMinorChanges,
            primaryChange: "Simulator analysis — no real changes detected.",
            confidence: .medium
        )

        return SkinAnalysisResult(
            scanId: scanId,
            userId: userId,
            createdAt: .now,
            quality: quality,
            zones: zones,
            summary: summary
        )
    }

    // MARK: - Private

    private struct ImageProperties {
        let brightness: Double // 0–1
        let warmth: Double     // 0–1
    }

    private static func analyzeImageProperties(_ image: UIImage) -> ImageProperties {
        guard let cgImage = image.cgImage else {
            return ImageProperties(brightness: 0.5, warmth: 0.5)
        }

        let width = min(cgImage.width, 100)
        let height = min(cgImage.height, 100)

        guard let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return ImageProperties(brightness: 0.5, warmth: 0.5)
        }

        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow
        var totalBrightness: Double = 0
        var totalWarmth: Double = 0

        for y in stride(from: 0, to: height, by: 5) {
            for x in stride(from: 0, to: width, by: 5) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = Double(bytes[offset])
                let g = Double(bytes[offset + 1])
                let b = Double(bytes[offset + 2])

                let brightness = (r + g + b) / (3.0 * 255.0)
                let warmth = r / max(r + g + b, 1.0)

                totalBrightness += brightness
                totalWarmth += warmth
            }
        }

        let sampleCount = Double((width / 5) * (height / 5))
        return ImageProperties(
            brightness: totalBrightness / sampleCount,
            warmth: totalWarmth / sampleCount
        )
    }

    private static func generateMetrics(
        for zone: SkinZone,
        imageProperties: ImageProperties
    ) -> [SkinMetricKey: SkinMetricScore] {
        // Use zone hash + image properties for deterministic variation
        let zoneSeed = abs(zone.hashValue % 100)
        let brightnessOffset = (imageProperties.brightness - 0.5) * 20
        let warmthOffset = (imageProperties.warmth - 0.5) * 15

        var metrics: [SkinMetricKey: SkinMetricScore] = [:]

        for key in SkinMetricKey.allCases {
            let baseScore = max(10, min(90, 40 + zoneSeed % 30))
            let adjusted = Int(Double(baseScore) + brightnessOffset + warmthOffset)
            let clamped = max(0, min(100, adjusted))

            let severity: String
            if clamped < 30 { severity = "low" }
            else if clamped < 60 { severity = "moderate" }
            else { severity = "elevated" }

            metrics[key] = SkinMetricScore(
                score: clamped,
                confidence: .medium,
                trend: .insufficientData,
                reason: "\(key.displayName) appears \(severity) in this zone."
            )
        }

        return metrics
    }

    private static func generateInsight(
        for zone: SkinZone,
        metrics: [SkinMetricKey: SkinMetricScore]
    ) -> String {
        let topMetric = metrics.max { $0.value.score < $1.value.score }?.key ?? .texture
        return "\(zone.displayName) shows visible \(topMetric.displayName.lowercased()) signs."
    }
}

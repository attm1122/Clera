import Foundation
import UIKit
import CoreVideo

enum SkinAnalysisPipeline {
    /// Runs the complete skin analysis pipeline on captured images.
    static func analyze(
        scanId: UUID,
        userId: String,
        frontImage: UIImage,
        leftImage: UIImage?,
        rightImage: UIImage?,
        landmarkDetector: FaceLandmarkDetector,
        baselineManager: BaselineManager
    ) async -> SkinAnalysisResult {
        // Step 1: Validate image quality on front image
        let quality = await validateQuality(for: frontImage)

        // Step 2: Detect face landmarks on front image
        let landmarks = await landmarkDetector.detectLandmarks(in: frontImage)

        // Step 3: Map landmarks to 5 zones
        let zonePaths = FaceZoneMapper.mapZones(from: landmarks)
        let skinMask = SkinMaskGenerator.generateSkinMask(from: frontImage, excluding: nil)

        // Steps 4 & 5: For each zone, generate mask and run metric analyzers
        var zoneAnalyses: [SkinZoneAnalysis] = []
        var allMetrics: [SkinZone: [SkinMetricKey: SkinMetricScore]] = [:]

        for zone in SkinZone.allCases {
            let zonePath = zonePaths[zone]
            let zoneMask = zonePath.flatMap {
                ZoneMaskGenerator.createMask(for: $0, imageSize: frontImage.size)
            }

            let metrics = SkinMetricEngine.analyzeZone(
                zone: zone,
                image: frontImage,
                skinMask: skinMask,
                zoneMask: zoneMask
            )
            allMetrics[zone] = metrics

            let topInsightText = SkinInsightGenerator.topInsight(
                for: SkinZoneAnalysis(zone: zone, metrics: metrics),
                baseline: baselineManager.currentBaseline
            )

            let zoneConfidence = computeZoneConfidence(from: metrics)

            let zoneAnalysis = SkinZoneAnalysis(
                zone: zone,
                metrics: metrics,
                topInsight: topInsightText,
                confidence: zoneConfidence,
                maskPath: zonePath,
                croppedImageFileName: nil
            )
            zoneAnalyses.append(zoneAnalysis)
        }

        // Step 6: Compare against baseline if exists
        let baseline = baselineManager.loadBaseline(userId: userId)
        let comparison: BaselineComparison?
        if let baseline = baseline {
            comparison = TrendAnalyzer.compare(current: allMetrics, baseline: baseline)
            for i in zoneAnalyses.indices {
                for metric in SkinMetricKey.allCases {
                    if let trend = comparison?.zoneComparisons[zoneAnalyses[i].zone]?[metric],
                       var score = zoneAnalyses[i].metrics[metric] {
                        score.trend = trend
                        zoneAnalyses[i].metrics[metric] = score
                    }
                }
            }
        } else {
            comparison = nil
        }

        // Step 7: Generate overall summary
        let summary = SkinInsightGenerator.generateSummary(
            zoneAnalyses: zoneAnalyses,
            comparison: comparison
        )

        // Save images to disk
        saveImages(
            scanId: scanId,
            frontImage: frontImage,
            leftImage: leftImage,
            rightImage: rightImage
        )

        // Step 8: Return result
        return SkinAnalysisResult(
            scanId: scanId,
            userId: userId,
            createdAt: .now,
            quality: quality,
            zones: zoneAnalyses,
            summary: summary
        )
    }
}

// MARK: - Private Helpers

private extension SkinAnalysisPipeline {
    static func validateQuality(for image: UIImage) async -> ScanQualityResult {
        guard let pixelBuffer = image.toCVPixelBuffer() else {
            return ScanQualityResult(
                accepted: false,
                lighting: .unknown,
                blur: .unknown,
                pose: .unknown,
                distance: .unknown,
                obstruction: .none,
                resolution: .unknown,
                confidence: .low,
                issues: ["Could not convert image for quality analysis"]
            )
        }

        let analyzer = NativeQualityAnalyzer()
        let metrics = analyzer.analyze(pixelBuffer)

        let blur: ScanQualityResult.BlurLevel
        if metrics.blurScore < 0.2 {
            blur = .high
        } else if metrics.blurScore < 0.5 {
            blur = .moderate
        } else {
            blur = .low
        }

        let lighting: LightingQuality = metrics.lightingQuality
        let accepted = metrics.lightingQuality == .good && metrics.blurScore >= 0.3

        return ScanQualityResult(
            accepted: accepted,
            lighting: lighting,
            blur: blur,
            pose: .valid,
            distance: .valid,
            obstruction: .none,
            resolution: .valid,
            confidence: accepted ? .high : .medium,
            issues: accepted ? [] : ["Image quality may affect analysis accuracy"]
        )
    }

    static func computeZoneConfidence(
        from metrics: [SkinMetricKey: SkinMetricScore]
    ) -> ScanQualityResult.QualityConfidence {
        let confidences = metrics.values.map(\.confidence)
        let highCount = confidences.filter { $0 == .high }.count
        let mediumCount = confidences.filter { $0 == .medium }.count
        let total = confidences.count

        guard total > 0 else { return .low }

        if highCount >= total / 2 {
            return .high
        } else if mediumCount + highCount >= total / 2 {
            return .medium
        } else {
            return .low
        }
    }

    static func saveImages(
        scanId: UUID,
        frontImage: UIImage,
        leftImage: UIImage?,
        rightImage: UIImage?
    ) {
        let frontFileName = ImageStore.generateFileName(angle: .front, scanId: scanId)
        ImageStore.save(frontImage, fileName: frontFileName)

        if let leftImage = leftImage {
            let leftFileName = ImageStore.generateFileName(angle: .left, scanId: scanId)
            ImageStore.save(leftImage, fileName: leftFileName)
        }

        if let rightImage = rightImage {
            let rightFileName = ImageStore.generateFileName(angle: .right, scanId: scanId)
            ImageStore.save(rightImage, fileName: rightFileName)
        }
    }
}

// MARK: - UIImage + CVPixelBuffer

private extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        guard let cgImage = self.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }
}

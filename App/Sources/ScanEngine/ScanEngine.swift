import CoreVideo
import Foundation

/// Orchestrates a single `VisionProvider` to produce `ScanReadinessResult`
/// for each camera frame. The UI never sees providers — only results.
final class ScanEngine: @unchecked Sendable {

    // MARK: - Configuration

    struct Configuration {
        var strategy: ProviderResolver.Strategy = ProviderResolver.defaultStrategy
        var idealBrightnessRange: ClosedRange<Double> = 0.25...0.75
        var minBlurScore: Double = 0.12
        var minSharpnessScore: Double = 0.08
        var minFaceArea: Double = 0.15
        var maxFaceArea: Double = 0.65
    }

    // MARK: - State

    private(set) var latestResult: ScanReadinessResult = ScanReadinessResult()
    private(set) var isAnalyzing: Bool = false

    private let provider: VisionProvider
    private let config: Configuration

    // MARK: - Init

    init(configuration: Configuration = Configuration()) {
        self.config = configuration
        self.provider = ProviderResolver.resolve(configuration.strategy)
    }

    // MARK: - Public API

    /// Analyzes a single frame and updates `latestResult`.
    func analyze(_ pixelBuffer: CVPixelBuffer) async {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        defer { isAnalyzing = false }

        let frameResult = await provider.analyzeFrame(pixelBuffer)
        latestResult = buildResult(from: frameResult)
    }

    /// Analyzes a captured photo for post-capture validation.
    func analyzeCapturedImage(_ cgImage: CGImage) async -> ScanReadinessResult {
        guard let pixelBuffer = cgImage.toPixelBuffer() else {
            return ScanReadinessResult(guidanceMessage: CleraCopy.ScanGuidance.couldNotAnalyze)
        }
        let frameResult = await provider.analyzeFrame(pixelBuffer)
        return buildResult(from: frameResult)
    }

    /// Resets the latest result to defaults.
    func reset() {
        latestResult = ScanReadinessResult()
    }

    // MARK: - Private

    private func buildResult(from frame: VisionFrameResult) -> ScanReadinessResult {
        var result = ScanReadinessResult()
        result.faceDetected = frame.faceDetected
        result.faceCentered = frame.faceCentered
        result.faceTooSmall = frame.faceTooSmall
        result.faceTooLarge = frame.faceTooLarge
        result.faceBounds = frame.faceBounds
        result.headPose = frame.headPose
        result.lightingQuality = frame.quality.lightingQuality
        result.blurScore = frame.quality.blurScore
        result.brightnessScore = frame.quality.brightnessScore
        result.contrastScore = frame.quality.contrastScore
        result.sharpnessScore = frame.quality.sharpnessScore
        result.overexposed = frame.quality.overexposed
        result.shadowDetected = frame.quality.shadowDetected
        result.confidenceScore = computeConfidence(frame: frame)
        result.scanReadiness = computeReadiness(frame: frame)
        result.guidanceMessage = computeGuidance(frame: frame, readiness: result.scanReadiness)
        return result
    }

    private func computeReadiness(frame: VisionFrameResult) -> ScanReadiness {
        guard frame.faceDetected else { return .notReady }
        guard !frame.faceTooSmall else { return .poorQuality }
        guard !frame.faceTooLarge else { return .poorQuality }
        guard frame.faceCentered else { return .poorQuality }
        guard let pose = frame.headPose, pose.isFrontal else { return .poorQuality }

        var score = 0
        if frame.quality.blurScore >= config.minBlurScore { score += 1 }
        if frame.quality.sharpnessScore >= config.minSharpnessScore { score += 1 }
        if config.idealBrightnessRange.contains(frame.quality.brightnessScore) { score += 1 }
        if !frame.quality.overexposed { score += 1 }
        if !frame.quality.shadowDetected { score += 1 }

        switch score {
        case 5: return .excellent
        case 4: return .good
        case 3: return .acceptable
        case 1...2: return .poorQuality
        default: return .notReady
        }
    }

    private func computeConfidence(frame: VisionFrameResult) -> Double {
        guard frame.faceDetected else { return 0 }
        var score = frame.confidence
        score *= (0.5 + 0.5 * frame.quality.blurScore)
        score *= (0.5 + 0.5 * frame.quality.sharpnessScore)
        if frame.quality.overexposed || frame.quality.shadowDetected { score *= 0.7 }
        if frame.faceTooSmall || frame.faceTooLarge { score *= 0.6 }
        return min(max(score, 0), 1)
    }

    private func computeGuidance(frame: VisionFrameResult, readiness: ScanReadiness) -> String {
        // Face presence
        if !frame.faceDetected {
            return CleraCopy.ScanGuidance.noFaceDetected
        }

        // Face size
        if frame.faceTooSmall {
            return CleraCopy.ScanGuidance.moveCloser
        }
        if frame.faceTooLarge {
            return CleraCopy.ScanGuidance.moveBack
        }

        // Face position
        if !frame.faceCentered {
            return CleraCopy.ScanGuidance.centreFace
        }

        // Head pose
        if let pose = frame.headPose {
            if pose.yaw < -0.15 {
                return CleraCopy.ScanGuidance.turnRight
            } else if pose.yaw > 0.15 {
                return CleraCopy.ScanGuidance.turnLeft
            }
            if pose.pitch < -0.15 {
                return CleraCopy.ScanGuidance.tiltDown
            } else if pose.pitch > 0.15 {
                return CleraCopy.ScanGuidance.tiltUp
            }
        }

        // Lighting
        if frame.quality.lightingQuality == .tooDark {
            return CleraCopy.ScanGuidance.improveLighting
        }
        if frame.quality.lightingQuality == .tooBright || frame.quality.overexposed {
            return CleraCopy.ScanGuidance.improveLighting
        }
        if frame.quality.lightingQuality == .uneven || frame.quality.shadowDetected {
            return CleraCopy.ScanGuidance.improveLighting
        }

        // Sharpness
        if frame.quality.blurScore < config.minBlurScore {
            return CleraCopy.ScanGuidance.holdSteady
        }

        // Ready
        if readiness == .excellent || readiness == .good {
            return CleraCopy.ScanGuidance.readyToScan
        }

        return "Hold still"
    }
}

// MARK: - CGImage → CVPixelBuffer helper

private extension CGImage {
    func toPixelBuffer() -> CVPixelBuffer? {
        let width = self.width
        let height = self.height
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs as CFDictionary,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, .init(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, .init(rawValue: 0)) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }

        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }
}

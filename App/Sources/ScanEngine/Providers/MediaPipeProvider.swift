import CoreVideo

// Stub placeholder — full MediaPipe implementation available in git history.
final class MediaPipeProvider: VisionProvider {
    private let qualityAnalyzer = NativeQualityAnalyzer()

    func analyzeFrame(_ pixelBuffer: CVPixelBuffer) async -> VisionFrameResult {
        return VisionFrameResult(quality: qualityAnalyzer.analyze(pixelBuffer))
    }
}

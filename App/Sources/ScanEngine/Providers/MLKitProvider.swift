import CoreVideo

// Stub placeholder — full ML Kit implementation available in git history.
final class MLKitProvider: VisionProvider {
    private let qualityAnalyzer = NativeQualityAnalyzer()

    func analyzeFrame(_ pixelBuffer: CVPixelBuffer) async -> VisionFrameResult {
        return VisionFrameResult(quality: qualityAnalyzer.analyze(pixelBuffer))
    }
}

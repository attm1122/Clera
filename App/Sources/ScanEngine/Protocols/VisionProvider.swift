import CoreVideo

/// Unified interface for all computer vision providers.
/// The UI never sees implementations — only `ScanReadinessResult`.
protocol VisionProvider {
    /// Analyzes a single camera frame and returns raw detection + quality data.
    func analyzeFrame(_ pixelBuffer: CVPixelBuffer) async -> VisionFrameResult
}

/// Raw per-frame output from any vision provider.
/// `ScanEngine` translates this into the UI-facing `ScanReadinessResult`.
struct VisionFrameResult: Sendable {
    var faceDetected: Bool = false
    var faceBounds: CGRect?
    var faceCentered: Bool = false
    var faceTooSmall: Bool = false
    var faceTooLarge: Bool = false
    var headPose: HeadPose?
    var confidence: Double = 0
    var quality: QualityMetrics = QualityMetrics()

    struct QualityMetrics: Sendable {
        var blurScore: Double = 0
        var brightnessScore: Double = 0
        var contrastScore: Double = 0
        var sharpnessScore: Double = 0
        var overexposed: Bool = false
        var shadowDetected: Bool = false
        var lightingQuality: LightingQuality = .unknown
    }
}

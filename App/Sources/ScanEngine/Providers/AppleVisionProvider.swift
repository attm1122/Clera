import CoreGraphics
import CoreVideo
import Vision

/// Native iOS face detection using Apple Vision.
/// Zero external dependencies. Fast, on-device, iOS 15+.
/// Used as the compile-time default until ML Kit is added.
final class AppleVisionProvider: VisionProvider {

    private let faceDetectionRequest: VNDetectFaceRectanglesRequest
    private let qualityAnalyzer = NativeQualityAnalyzer()

    init() {
        faceDetectionRequest = VNDetectFaceRectanglesRequest()
        faceDetectionRequest.revision = VNDetectFaceRectanglesRequestRevision3
    }

    func analyzeFrame(_ pixelBuffer: CVPixelBuffer) async -> VisionFrameResult {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

        do {
            try handler.perform([faceDetectionRequest])
        } catch {
            return VisionFrameResult(quality: qualityAnalyzer.analyze(pixelBuffer))
        }

        guard let face = faceDetectionRequest.results?.first as? VNFaceObservation else {
            return VisionFrameResult(quality: qualityAnalyzer.analyze(pixelBuffer))
        }

        let imageSize = CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )

        let bounds = VNImageRectForNormalizedRect(face.boundingBox, Int(imageSize.width), Int(imageSize.height))
        let centered = isFaceCentered(face.boundingBox)
        let sizeStatus = faceSizeStatus(face.boundingBox)
        let pose = extractHeadPose(from: face)
        let confidence = Double(face.confidence)
        let quality = qualityAnalyzer.analyze(pixelBuffer)

        return VisionFrameResult(
            faceDetected: true,
            faceBounds: bounds,
            faceCentered: centered,
            faceTooSmall: sizeStatus == .tooSmall,
            faceTooLarge: sizeStatus == .tooLarge,
            headPose: pose,
            confidence: confidence,
            quality: quality
        )
    }

    private func isFaceCentered(_ normalizedBounds: CGRect) -> Bool {
        abs(normalizedBounds.midX - 0.5) < 0.15 && abs(normalizedBounds.midY - 0.5) < 0.15
    }

    private enum FaceSizeStatus {
        case good, tooSmall, tooLarge
    }

    private func faceSizeStatus(_ normalizedBounds: CGRect) -> FaceSizeStatus {
        let area = normalizedBounds.width * normalizedBounds.height
        if area < 0.15 { return .tooSmall }
        if area > 0.65 { return .tooLarge }
        return .good
    }

    private func extractHeadPose(from observation: VNFaceObservation) -> HeadPose? {
        guard let yaw = observation.yaw?.doubleValue,
              let roll = observation.roll?.doubleValue else {
            return nil
        }
        return HeadPose(pitch: 0, yaw: yaw, roll: roll)
    }
}

import UIKit
import Vision

/// Apple Vision implementation of `FaceLandmarkDetector`.
/// Uses `VNDetectFaceLandmarksRequest` (revision 3) to extract all available
/// 2D face landmarks on-device with zero external dependencies.
///
/// Coordinate system: Vision returns normalized coordinates with the origin at the
/// **bottom-left** of the image. This implementation flips the Y axis so that all
/// output points use the UIKit convention (origin **top-left**, normalized 0–1).
final class AppleVisionLandmarkDetector: FaceLandmarkDetector, @unchecked Sendable {

    func detectLandmarks(in image: UIImage) async -> FaceLandmarkResult {
        guard let cgImage = image.cgImage else {
            return FaceLandmarkResult()
        }

        let request = VNDetectFaceLandmarksRequest()
        request.revision = VNDetectFaceLandmarksRequestRevision3

        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: .up,
            options: [:]
        )

        do {
            try handler.perform([request])
        } catch {
            return FaceLandmarkResult()
        }

        guard let observation = request.results?.first as? VNFaceObservation else {
            return FaceLandmarkResult()
        }

        var result = FaceLandmarkResult()
        result.faceDetected = true
        result.confidence = Double(observation.confidence)
        result.boundingBox = convertBoundingBox(observation.boundingBox)
        result.headPose = extractHeadPose(from: observation)
        result.landmarks = extractAllLandmarks(from: observation)

        return result
    }

    // MARK: - Coordinate Conversion

    /// Vision uses a bottom-left origin; UIKit uses top-left.
    /// Flip the Y axis while keeping X unchanged.
    private func convertBoundingBox(_ box: CGRect) -> CGRect {
        CGRect(
            x: box.origin.x,
            y: 1.0 - box.origin.y - box.height,
            width: box.width,
            height: box.height
        )
    }

    /// Flips a single normalized point from Vision coordinates to UIKit coordinates.
    private func convertPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x, y: 1.0 - point.y)
    }

    /// Flips an array of normalized points from Vision coordinates to UIKit coordinates.
    private func convertPoints(_ points: [CGPoint]) -> [CGPoint] {
        points.map(convertPoint)
    }

    // MARK: - Head Pose

    private func extractHeadPose(from observation: VNFaceObservation) -> HeadPose {
        HeadPose(
            pitch: observation.pitch?.doubleValue ?? 0,
            yaw: observation.yaw?.doubleValue ?? 0,
            roll: observation.roll?.doubleValue ?? 0
        )
    }

    // MARK: - Landmark Extraction

    /// Extracts every landmark region supported by Vision revision 3 and maps it to
    /// the app's `FaceLandmarkResult.FaceLandmark` model.
    private func extractAllLandmarks(from observation: VNFaceObservation) -> [FaceLandmarkResult.FaceLandmark] {
        guard let landmarks = observation.landmarks else {
            return []
        }

        var result: [FaceLandmarkResult.FaceLandmark] = []

        // Face contour — outer boundary of the face.
        if let region = landmarks.faceContour {
            result.append(.init(type: .faceContour, points: convertPoints(region.normalizedPoints)))
        }

        // Eyebrows
        if let region = landmarks.leftEyebrow {
            result.append(.init(type: .leftEyebrow, points: convertPoints(region.normalizedPoints)))
        }
        if let region = landmarks.rightEyebrow {
            result.append(.init(type: .rightEyebrow, points: convertPoints(region.normalizedPoints)))
        }

        // Eyes
        if let region = landmarks.leftEye {
            result.append(.init(type: .leftEye, points: convertPoints(region.normalizedPoints)))
        }
        if let region = landmarks.rightEye {
            result.append(.init(type: .rightEye, points: convertPoints(region.normalizedPoints)))
        }

        // Nose — Vision's `nose` region outlines the cartilaginous nose.
        // We map it to `.noseTip` because it contains the tip and surrounding
        // nasal area needed for zone polygon construction.
        if let region = landmarks.nose {
            result.append(.init(type: .noseTip, points: convertPoints(region.normalizedPoints)))
        }

        // Nose crest — the bridge of the nose.
        if let region = landmarks.noseCrest {
            result.append(.init(type: .noseCrest, points: convertPoints(region.normalizedPoints)))
        }

        // Lips
        if let region = landmarks.outerLips {
            result.append(.init(type: .outerLips, points: convertPoints(region.normalizedPoints)))
        }
        if let region = landmarks.innerLips {
            result.append(.init(type: .innerLips, points: convertPoints(region.normalizedPoints)))
        }

        // Pupils
        if let region = landmarks.leftPupil {
            result.append(.init(type: .leftPupil, points: convertPoints(region.normalizedPoints)))
        }
        if let region = landmarks.rightPupil {
            result.append(.init(type: .rightPupil, points: convertPoints(region.normalizedPoints)))
        }

        // Median line — central axis of the face (revision 3+).
        if let region = landmarks.medianLine {
            result.append(.init(type: .medianLine, points: convertPoints(region.normalizedPoints)))
        }

        return result
    }
}

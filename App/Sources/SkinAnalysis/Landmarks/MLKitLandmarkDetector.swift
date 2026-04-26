import UIKit

/// **Stub** — Google ML Kit Face Detection implementation of `FaceLandmarkDetector`.
///
/// To wire this in later:
/// 1. Add the ML Kit Face Detection dependency (e.g. via CocoaPods:
///    `pod 'GoogleMLKit/FaceDetection'`).
/// 2. Create a `FaceDetector` using `FaceDetectorOptions`.
///    - Enable `FaceDetectorOptions().classificationMode = .all`
///    - Enable `FaceDetectorOptions().landmarkMode = .all`
///    - Enable `FaceDetectorOptions().contourMode = .all`
/// 3. Convert the `UIImage` to a `VisionImage` (`MLKitVision.VisionImage`).
/// 4. Call `faceDetector.process(visionImage)`.
/// 5. Map ML Kit landmarks to `FaceLandmarkResult.FaceLandmark`:
///    - Use `face.contours` for face contour, eyebrows, eyes, nose bridge, nose bottom,
///      lips, and pupil positions.
///    - Normalize pixel coordinates by the image width/height to get 0–1 values.
///    - Ensure the Y axis uses the UIKit convention (origin top-left).
/// 6. Extract head pose Euler angles from `face.headEulerAngleX/Y/Z` if available.
/// 7. Return a populated `FaceLandmarkResult`.
///
/// Because ML Kit is not yet integrated into the build, this stub returns
/// an empty result so the module compiles independently.
struct MLKitLandmarkDetector: FaceLandmarkDetector {

    func detectLandmarks(in image: UIImage) async -> FaceLandmarkResult {
        // Stub: ML Kit dependency not yet integrated. Returns empty result.
        return FaceLandmarkResult()
    }
}

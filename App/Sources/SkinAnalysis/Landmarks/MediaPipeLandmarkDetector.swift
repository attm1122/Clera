import UIKit

/// **Stub** — MediaPipe Face Landmarker implementation of `FaceLandmarkDetector`.
///
/// To wire this in later:
/// 1. Add the MediaPipe `FaceLandmarker` dependency (e.g. via CocoaPods:
///    `pod 'MediaPipeTasksVision'`).
/// 2. Initialize `FaceLandmarker` with a `.task` model file (e.g. `face_landmarker.task`).
/// 3. Convert the input `UIImage` to an `MPImage`.
/// 4. Call `faceLandmarker.detect(videoFrame:)` or `detect(image:)`.
/// 5. Map the 468 (or 478) output landmarks to `FaceLandmarkResult.FaceLandmark`.
///    - MediaPipe indices 10–19 roughly correspond to the face contour.
///    - Indices 105–334 correspond to the eyes, eyebrows, nose, and lips.
///    - Normalize landmark `x` and `y` values (already 0–1) and flip the Y axis
///      if MediaPipe uses a bottom-left origin in your configuration.
/// 6. Compute the bounding box from the min/max x/y of all face landmarks.
/// 7. Return a populated `FaceLandmarkResult`.
///
/// Because MediaPipe is not yet integrated into the build, this stub returns
/// an empty result so the module compiles independently.
struct MediaPipeLandmarkDetector: FaceLandmarkDetector {

    func detectLandmarks(in image: UIImage) async -> FaceLandmarkResult {
        // TODO: Replace with actual MediaPipe Face Landmarker inference.
        return FaceLandmarkResult()
    }
}

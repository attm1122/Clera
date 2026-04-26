import UIKit

/// Protocol for face landmark detection providers.
/// Implementations may use Apple Vision, MediaPipe, Google ML Kit, or other backends.
/// All implementations must be safe for use in concurrent contexts.
protocol FaceLandmarkDetector: Sendable {
    /// Detects facial landmarks in the given image.
    /// - Parameter image: A `UIImage` containing a face.
    /// - Returns: A `FaceLandmarkResult` with normalized landmark coordinates (0–1, UIKit origin).
    func detectLandmarks(in image: UIImage) async -> FaceLandmarkResult
}

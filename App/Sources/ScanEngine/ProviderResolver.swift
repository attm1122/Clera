import Foundation

/// Selects the appropriate vision provider based on build configuration,
/// OS capabilities, and future feature flags.
///
/// Strategy priority:
/// 1. Google ML Kit — primary MVP target (best cross-platform face detection)
/// 2. Apple Vision — native iOS fallback (zero dependencies, always available)
/// 3. MediaPipe Face Mesh — advanced landmarking (future, requires model file)
enum ProviderResolver {

    enum Strategy: Sendable {
        /// Google ML Kit Face Detection — intended MVP default.
        /// Requires adding `GoogleMLKit/FaceDetection` dependency.
        case mlKit

        /// Apple Vision — native iOS fallback.
        /// Zero external dependencies. Used when ML Kit is unavailable.
        case appleVision

        /// MediaPipe Face Mesh — future advanced landmarking.
        /// Requires `face_landmarker.task` model file + MediaPipe dependency.
        case mediaPipe
    }

    /// Returns the provider for the given strategy.
    /// Stubs gracefully degrade to Apple Vision if external deps are missing.
    static func resolve(_ strategy: Strategy) -> VisionProvider {
        switch strategy {
        case .mlKit:
            // MLKitProvider compiles as a stub until the dependency is added.
            // Once added, uncomment the full implementation in MLKitProvider.swift.
            return MLKitProvider()

        case .appleVision:
            return AppleVisionProvider()

        case .mediaPipe:
            // MediaPipeProvider compiles as a stub until the dependency + model are added.
            return MediaPipeProvider()
        }
    }

    /// Recommended default for the current build.
    static var defaultStrategy: Strategy {
        // TODO: Switch to `.mlKit` after adding the GoogleMLKit dependency.
        // For now, `.appleVision` guarantees the app builds without external packages.
        .appleVision
    }
}

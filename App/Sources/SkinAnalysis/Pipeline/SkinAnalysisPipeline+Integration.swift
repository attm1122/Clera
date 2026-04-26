import Foundation
import UIKit

extension SkinAnalysisPipeline {
    /// Convenience method that uses default detector and baseline manager.
    /// Automatically uses simulator-aware mock analysis when running on iOS Simulator,
    /// since Vision face detection requires a physical device.
    static func analyzeForUser(
        userId: String,
        frontImage: UIImage,
        leftImage: UIImage? = nil,
        rightImage: UIImage? = nil
    ) async -> SkinAnalysisResult {
        if SimulatorSkinAnalyzer.isRunningOnSimulator {
            return SimulatorSkinAnalyzer.analyze(
                scanId: UUID(),
                userId: userId,
                frontImage: frontImage
            )
        }

        return await analyze(
            scanId: UUID(),
            userId: userId,
            frontImage: frontImage,
            leftImage: leftImage,
            rightImage: rightImage,
            landmarkDetector: AppleVisionLandmarkDetector(),
            baselineManager: BaselineManager()
        )
    }
}

import Foundation
import Observation
import UIKit

/// Manages creation, storage, and retrieval of a user's skin baseline.
@Observable
final class BaselineManager {
    private let persistence: AppPersistence

    var currentBaseline: SkinBaseline?

    init(persistence: AppPersistence = AppPersistence()) {
        self.persistence = persistence
        self.currentBaseline = persistence.load()?.skinBaseline
    }

    /// Creates a baseline from the first accepted scan's zone analyses.
    @MainActor func createBaseline(from scan: SkinScan, userId: String) -> SkinBaseline {
        var zoneScores: [SkinZone: [SkinMetricKey: Int]] = [:]

        for zoneAnalysis in scan.zoneAnalyses {
            var metricScores: [SkinMetricKey: Int] = [:]
            for (key, score) in zoneAnalysis.metrics {
                metricScores[key] = score.score
            }
            zoneScores[zoneAnalysis.zone] = metricScores
        }

        let baseline = SkinBaseline(
            id: UUID(),
            userId: userId,
            createdAt: scan.createdAt,
            scanId: scan.id,
            zoneScores: zoneScores,
            lightingMetadata: SkinBaseline.LightingMetadata(
                brightness: scan.quality.lighting == .good ? 0.5 : 0.3,
                contrast: 0.5,
                colorTemperature: nil
            ),
            deviceMetadata: SkinBaseline.DeviceMetadata(
                deviceModel: UIDevice.current.model,
                cameraPosition: "front",
                resolution: "\(scan.images.first?.id.uuidString ?? "unknown")"
            )
        )

        currentBaseline = baseline
        saveBaseline(baseline)
        return baseline
    }

    func hasBaseline(for userId: String) -> Bool {
        currentBaseline?.userId == userId
    }

    func loadBaseline(userId: String) -> SkinBaseline? {
        if let baseline = currentBaseline, baseline.userId == userId {
            return baseline
        }
        currentBaseline = persistence.load()?.skinBaseline
        return currentBaseline
    }

    func saveBaseline(_ baseline: SkinBaseline) {
        currentBaseline = baseline
        if var state = persistence.load() {
            state.skinBaseline = baseline
            persistence.save(state)
        }
    }

    func clearBaseline() {
        currentBaseline = nil
        if var state = persistence.load() {
            state.skinBaseline = nil
            persistence.save(state)
        }
    }
}

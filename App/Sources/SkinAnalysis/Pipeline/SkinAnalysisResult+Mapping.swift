import Foundation

/// Maps `SkinAnalysisResult` to the existing `SkinMap` model used by the rest of the app.
extension SkinAnalysisResult {

    func toSkinMap(checkIn: SkinMapCheckIn? = nil, scanQuality: ScanQualityMetadata? = nil) -> SkinMap {
        let faceZones = zones.map { zoneAnalysis in
            FaceZone(
                zoneType: zoneAnalysis.zone.toZoneType(),
                status: zoneAnalysis.toZoneStatus()
            )
        }

        return SkinMap(
            zones: faceZones,
            checkIn: checkIn,
            scanQuality: scanQuality
        )
    }
}

private extension SkinZone {
    func toZoneType() -> ZoneType {
        switch self {
        case .forehead: .forehead
        case .nose: .nose
        case .leftCheek: .leftCheek
        case .rightCheek: .rightCheek
        case .chinJaw: .chinJaw
        }
    }
}

private extension SkinZoneAnalysis {
    func toZoneStatus() -> ZoneStatus {
        ZoneStatus(
            breakouts: severityFromMetric(.breakoutLikeSpots),
            redness: severityFromMetric(.redness),
            dryness: severityFromMetric(.dryness),
            texture: severityFromMetric(.texture),
            congestion: severityFromMetric(.shine),
            irritation: severityFromMetric(.redness),
            breakoutsTrend: trendFromMetric(.breakoutLikeSpots),
            rednessTrend: trendFromMetric(.redness),
            drynessTrend: trendFromMetric(.dryness),
            textureTrend: trendFromMetric(.texture),
            congestionTrend: trendFromMetric(.shine),
            irritationTrend: trendFromMetric(.redness)
        )
    }

    private func severityFromMetric(_ key: SkinMetricKey) -> ZoneSeverity {
        guard let score = metrics[key] else { return .none }
        switch score.score {
        case 0..<20: return .none
        case 20..<45: return .low
        case 45..<70: return .moderate
        default: return .high
        }
    }

    private func trendFromMetric(_ key: SkinMetricKey) -> ZoneTrend {
        guard let score = metrics[key] else { return .unknown }
        switch score.trend {
        case .improved, .slightlyReduced, .reduced: return .improving
        case .stable: return .stable
        case .increased, .slightlyIncreased: return .worsening
        case .insufficientData: return .unknown
        }
    }
}

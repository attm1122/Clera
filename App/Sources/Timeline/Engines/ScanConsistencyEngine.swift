import Foundation

/// Calculates how consistent a scan is with the user's baseline and recent scans.
/// Poor consistency reduces confidence in change detection and timeline insights.
enum ScanConsistencyEngine {

    /// Computes a full consistency report for a single scan.
    static func analyze(
        scan: ScanSession,
        baseline: SkinBaseline?,
        recentScans: [ScanSession],
        scanQuality: ScanQualityMetadata?
    ) -> ScanConsistency {

        guard let quality = scanQuality else {
            // No metadata available — neutral score so we don't punish every baseline scan.
            // Dimensions are unknown, but confidence impact is only minor
            // since we simply lack data rather than detecting poor conditions.
            return ScanConsistency(
                score: 50,
                lighting: .unknown,
                angle: .unknown,
                distance: .unknown,
                blur: .unknown,
                timeOfDay: .unknown,
                landmarkAlignment: .unknown,
                confidenceImpact: .minor
            )
        }

        // Gather reference conditions
        let baselineQuality = baseline?.lightingMetadata
        let rollingAverage = computeRollingAverage(from: recentScans)
        // Compute per-dimension scores (0.0 ... 1.0)
        let lightingScore = compareLighting(
            current: quality,
            baseline: baselineQuality,
            rolling: rollingAverage?.quality
        )

        let blurScore = compareBlur(
            current: quality.blurScore,
            baseline: baseline?.deviceMetadata.resolution != nil ? 0.5 : nil, // proxy
            rolling: rollingAverage?.blurScore
        )

        let distanceScore = compareDistance(
            current: quality,
            baseline: baseline?.lightingMetadata,
            rolling: rollingAverage?.quality
        )

        let timeOfDayScore = compareTimeOfDay(
            current: scan.createdAt,
            baseline: baseline?.createdAt,
            recent: recentScans.map(\.createdAt)
        )

        // Face angle consistency — use scan readiness as proxy
        let angleScore = angleConsistency(from: quality)

        // Landmark alignment — use sharpness as proxy
        let landmarkScore = landmarkAlignment(from: quality)

        // Weighted overall score
        let weightedScore = weightedOverallScore(
            lighting: lightingScore,
            blur: blurScore,
            distance: distanceScore,
            angle: angleScore,
            landmark: landmarkScore,
            timeOfDay: timeOfDayScore
        )

        let overallScore = Int(weightedScore * 100)

        return ScanConsistency(
            score: overallScore,
            lighting: dimensionStatus(for: lightingScore),
            angle: dimensionStatus(for: angleScore),
            distance: dimensionStatus(for: distanceScore),
            blur: dimensionStatus(for: blurScore),
            timeOfDay: dimensionStatus(for: timeOfDayScore),
            landmarkAlignment: dimensionStatus(for: landmarkScore),
            confidenceImpact: confidenceImpact(for: overallScore)
        )
    }

    // MARK: - Private

    private struct RollingAverage {
        var quality: ScanQualityMetadata?
        var blurScore: Double?
    }

    private static func computeRollingAverage(from scans: [ScanSession]) -> RollingAverage? {
        guard !scans.isEmpty else { return nil }
        let recent = scans.suffix(5)
        let qualities = recent.compactMap { $0.skinMap.scanQuality }
        guard !qualities.isEmpty else { return nil }

        let avgBlur = qualities.map(\.blurScore).reduce(0, +) / Double(qualities.count)
        let avgBrightness = qualities.map(\.brightnessScore).reduce(0, +) / Double(qualities.count)
        let avgSharpness = qualities.map(\.sharpnessScore).reduce(0, +) / Double(qualities.count)

        return RollingAverage(
            quality: ScanQualityMetadata(
                blurScore: avgBlur,
                brightnessScore: avgBrightness,
                sharpnessScore: avgSharpness,
                overexposed: false,
                shadowDetected: false,
                scanReadiness: "rolling_average"
            ),
            blurScore: avgBlur
        )
    }

    private static func compareLighting(
        current: ScanQualityMetadata,
        baseline: SkinBaseline.LightingMetadata?,
        rolling: ScanQualityMetadata?
    ) -> Double {
        var scores: [Double] = []

        // Compare brightness
        if let rolling = rolling {
            let brightnessDiff = abs(current.brightnessScore - rolling.brightnessScore)
            scores.append(max(0, 1.0 - brightnessDiff * 2.0))
        }

        // Overexposure / shadow consistency
        if current.overexposed || current.shadowDetected {
            scores.append(0.5)
        } else {
            scores.append(1.0)
        }

        return scores.isEmpty ? 0.5 : scores.reduce(0, +) / Double(scores.count)
    }

    private static func compareBlur(
        current: Double,
        baseline: Double?,
        rolling: Double?
    ) -> Double {
        var scores: [Double] = []

        if let baseline = baseline {
            let diff = abs(current - baseline)
            scores.append(max(0, 1.0 - diff * 3.0))
        }

        if let rolling = rolling {
            let diff = abs(current - rolling)
            scores.append(max(0, 1.0 - diff * 3.0))
        }

        // Raw blur score quality
        scores.append(min(current * 2.0, 1.0))

        return scores.reduce(0, +) / Double(scores.count)
    }

    private static func compareDistance(
        current: ScanQualityMetadata,
        baseline: SkinBaseline.LightingMetadata?,
        rolling: ScanQualityMetadata?
    ) -> Double {
        // Use brightness as proxy for distance (closer = brighter typically)
        var scores: [Double] = []

        if let rolling = rolling {
            let diff = abs(current.brightnessScore - rolling.brightnessScore)
            scores.append(max(0, 1.0 - diff * 1.5))
        }

        return scores.isEmpty ? 0.7 : scores.reduce(0, +) / Double(scores.count)
    }

    private static func compareTimeOfDay(
        current: Date,
        baseline: Date?,
        recent: [Date]
    ) -> Double {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: current)

        var scores: [Double] = []

        if let baseline = baseline {
            let baselineHour = calendar.component(.hour, from: baseline)
            let hourDiff = abs(currentHour - baselineHour)
            let normalizedDiff = min(Double(hourDiff) / 6.0, 1.0) // 6+ hours = max diff
            scores.append(1.0 - normalizedDiff)
        }

        if !recent.isEmpty {
            let recentHours = recent.map { calendar.component(.hour, from: $0) }
            let avgDiff = recentHours.map { abs($0 - currentHour) }.reduce(0, +) / recentHours.count
            let normalizedDiff = min(Double(avgDiff) / 6.0, 1.0)
            scores.append(1.0 - normalizedDiff)
        }

        return scores.isEmpty ? 0.7 : scores.reduce(0, +) / Double(scores.count)
    }

    private static func angleConsistency(from quality: ScanQualityMetadata) -> Double {
        let readiness = quality.scanReadiness.lowercased()
        if readiness.contains("excellent") { return 1.0 }
        if readiness.contains("good") { return 0.85 }
        if readiness.contains("acceptable") { return 0.65 }
        if readiness.contains("poor") { return 0.4 }
        return 0.2
    }

    private static func landmarkAlignment(from quality: ScanQualityMetadata) -> Double {
        // Use sharpness as proxy for landmark detection quality
        let sharpness = quality.sharpnessScore
        if sharpness >= 0.3 { return 1.0 }
        if sharpness >= 0.2 { return 0.8 }
        if sharpness >= 0.1 { return 0.5 }
        return 0.3
    }

    private static func weightedOverallScore(
        lighting: Double,
        blur: Double,
        distance: Double,
        angle: Double,
        landmark: Double,
        timeOfDay: Double
    ) -> Double {
        let weights: [Double] = [0.20, 0.20, 0.10, 0.20, 0.15, 0.15]
        let values = [lighting, blur, distance, angle, landmark, timeOfDay]
        return zip(values, weights).map(*).reduce(0, +)
    }

    private static func dimensionStatus(for score: Double) -> ScanConsistency.ConsistencyDimension {
        switch score {
        case 0.80...1.0: return .consistent
        case 0.55..<0.80: return .slightlyDifferent
        default: return .different
        }
    }

    private static func confidenceImpact(for score: Int) -> ScanConsistency.ConfidenceImpact {
        switch score {
        case 80...100: return .none
        case 60..<80: return .minor
        case 40..<60: return .moderate
        default: return .significant
        }
    }
}

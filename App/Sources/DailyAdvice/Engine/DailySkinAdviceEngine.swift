import Foundation

// MARK: - Daily Skin Advice Engine

enum DailySkinAdviceEngine {

    struct EngineInputs {
        let skinProfile: SkinProfile
        let latestSkinMap: SkinMap?
        let sessions: [ScanSession]
        let routineLogs: [RoutineLogEntry]
        let currentProducts: [Product]
        let timeOfDay: TimeOfDay
    }

    static func generateAdvice(
        inputs: EngineInputs,
        environment: CompositeEnvironmentProvider
    ) async -> DailySkinAdviceResult {
        let (weather, uv, airQuality) = await environment.fetchAll()
        let weatherWithUV = DailyWeatherSnapshot(
            uvIndex: uv,
            temperatureCelsius: weather.temperatureCelsius,
            humidityPercent: weather.humidityPercent,
            windSpeedKmh: weather.windSpeedKmh,
            condition: weather.condition
        )

        let scanContext = buildScanContext(inputs: inputs)
        let routineContext = buildRoutineContext(inputs: inputs)

        let riskInputs = SkinRiskScorer.RiskInputs(
            weather: weatherWithUV,
            airQuality: airQuality,
            skinProfile: inputs.skinProfile,
            scanContext: scanContext,
            routineContext: routineContext
        )
        let riskBreakdown = SkinRiskScorer.calculate(inputs: riskInputs)

        let copyInputs = AdviceCopyEngine.CopyInputs(
            riskBreakdown: riskBreakdown,
            timeOfDay: inputs.timeOfDay,
            weather: weatherWithUV,
            airQuality: airQuality,
            skinProfile: inputs.skinProfile,
            scanContext: scanContext,
            routineContext: routineContext
        )
        let copy = AdviceCopyEngine.generate(inputs: copyInputs)

        let confidence = determineConfidence(
            hasWeather: weather.condition != .unknown,
            hasScan: scanContext.latestScanDate != nil,
            hasRoutineData: !inputs.routineLogs.isEmpty
        )

        return DailySkinAdviceResult(
            id: UUID(),
            generatedAt: .now,
            timeOfDay: inputs.timeOfDay,
            riskLevel: riskBreakdown.level,
            riskScore: riskBreakdown.totalScore,
            primaryAdvice: copy.primaryAdvice,
            secondaryAdvice: copy.secondaryAdvice,
            recommendedActions: copy.actions,
            affectedZones: copy.affectedZones,
            confidence: confidence,
            dataSourcesUsed: copy.dataSources,
            weatherSnapshot: weatherWithUV,
            airQualitySnapshot: airQuality,
            environmentFactors: copy.factors,
            scanContext: scanContext,
            routineContext: routineContext
        )
    }

    // MARK: - Context Builders

    static func buildScanContext(inputs: EngineInputs) -> ScanContext {
        let calendar = Calendar.current
        let latestSession = inputs.sessions.sorted(by: { $0.createdAt > $1.createdAt }).first
        let daysSince = latestSession.map {
            calendar.dateComponents([.day], from: $0.createdAt, to: .now).day ?? 0
        } ?? 999

        let recentMaps = inputs.sessions
            .filter { calendar.dateComponents([.day], from: $0.createdAt, to: .now).day ?? 999 <= 14 }
            .map(\.skinMap)

        let hasIrritation = recentMaps.contains { $0.checkIn?.hadIrritation == true }
        let hasBreakouts = recentMaps.contains { $0.checkIn?.hadBreakouts == true }
        let hasDryness = recentMaps.contains { $0.checkIn?.hadDryness == true }

        let worseningZones = detectWorseningZones(sessions: inputs.sessions)

        return ScanContext(
            daysSinceLastScan: daysSince,
            latestScanDate: latestSession?.createdAt,
            hasRecentIrritation: hasIrritation,
            hasRecentBreakouts: hasBreakouts,
            hasRecentDryness: hasDryness,
            worseningZones: worseningZones
        )
    }

    static func buildRoutineContext(inputs: EngineInputs) -> RoutineContext {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        let weekLogs = inputs.routineLogs.filter { $0.date >= weekAgo }
        let adherence = weekLogs.isEmpty ? 0.0 : Double(weekLogs.filter(\.followedRoutine).count) / 14.0
        let missedDays = max(0, 7 - Set(weekLogs.map { calendar.startOfDay(for: $0.date) }).count)

        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: .now) ?? .now
        let recentLogs = inputs.routineLogs.filter { $0.date >= twoDaysAgo }
        let recentProductIDs = recentLogs.flatMap(\.productIDs)
        let recentProducts = inputs.currentProducts.filter { recentProductIDs.contains($0.id) }

        let usedExfoliant = recentProducts.contains {
            $0.ingredientTags.contains(.aha) || $0.ingredientTags.contains(.bha)
        }
        let usedRetinol = recentProducts.contains {
            $0.ingredientTags.contains(.retinol)
        }
        let hasSPF = inputs.currentProducts.contains {
            $0.isActive && ($0.period == .morning || $0.period == .both) &&
            ($0.ingredientTags.contains(.spf) || $0.category == .sunscreen)
        }

        return RoutineContext(
            adherenceThisWeek: min(adherence, 1.0),
            missedDaysCount: missedDays,
            recentlyUsedExfoliant: usedExfoliant,
            recentlyUsedRetinol: usedRetinol,
            spfPresentInRoutine: hasSPF
        )
    }

    // MARK: - Helpers

    private static func detectWorseningZones(sessions: [ScanSession]) -> [ZoneType] {
        guard sessions.count >= 2 else { return [] }
        let sorted = sessions.sorted(by: { $0.createdAt > $1.createdAt })
        guard let latest = sorted.first, let previous = sorted.dropFirst().first else { return [] }

        var worsening: [ZoneType] = []
        for zone in latest.skinMap.zones {
            guard let prevZone = previous.skinMap.zones.first(where: { $0.zoneType == zone.zoneType })
            else { continue }
            if zone.status.redness.rawValue > prevZone.status.redness.rawValue ||
               zone.status.breakouts.rawValue > prevZone.status.breakouts.rawValue ||
               zone.status.texture.rawValue > prevZone.status.texture.rawValue {
                worsening.append(zone.zoneType)
            }
        }
        return worsening
    }

    private static func determineConfidence(
        hasWeather: Bool,
        hasScan: Bool,
        hasRoutineData: Bool
    ) -> InsightConfidence {
        var score = 0
        if hasWeather { score += 1 }
        if hasScan { score += 1 }
        if hasRoutineData { score += 1 }
        switch score {
        case 3: return .high
        case 2: return .moderate
        default: return .low
        }
    }
}

import Foundation

// MARK: - Skin Risk Scorer

enum SkinRiskScorer {

    struct RiskInputs {
        let weather: DailyWeatherSnapshot
        let airQuality: AirQualitySnapshot
        let skinProfile: SkinProfile
        let scanContext: ScanContext
        let routineContext: RoutineContext
    }

    struct RiskBreakdown {
        let uvScore: Int
        let humidityScore: Int
        let temperatureScore: Int
        let windScore: Int
        let airQualityScore: Int
        let skinProfileScore: Int
        let scanTrendScore: Int
        let routineScore: Int
        let totalScore: Int
        let level: SkinRiskLevel
    }

    static func calculate(inputs: RiskInputs) -> RiskBreakdown {
        let uvScore = scoreUV(inputs.weather.uvIndex)
        let humidityScore = scoreHumidity(inputs.weather.humidityPercent, skinType: inputs.skinProfile.skinType)
        let temperatureScore = scoreTemperature(inputs.weather.temperatureCelsius)
        let windScore = scoreWind(inputs.weather.windSpeedKmh)
        let airQualityScore = scoreAirQuality(inputs.airQuality.aqi)
        let skinProfileScore = scoreSkinProfile(inputs.skinProfile, weather: inputs.weather)
        let scanTrendScore = scoreScanTrend(inputs.scanContext)
        let routineScore = scoreRoutine(inputs.routineContext)

        let rawTotal = uvScore + humidityScore + temperatureScore + windScore +
                       airQualityScore + skinProfileScore + scanTrendScore + routineScore
        let totalScore = min(rawTotal, 100)

        return RiskBreakdown(
            uvScore: uvScore,
            humidityScore: humidityScore,
            temperatureScore: temperatureScore,
            windScore: windScore,
            airQualityScore: airQualityScore,
            skinProfileScore: skinProfileScore,
            scanTrendScore: scanTrendScore,
            routineScore: routineScore,
            totalScore: totalScore,
            level: SkinRiskLevel.from(score: totalScore)
        )
    }

    // MARK: - Individual Scorers

    static func scoreUV(_ uvIndex: Double) -> Int {
        switch uvIndex {
        case 0...2: return 0
        case 2.1...3: return 5
        case 3.1...5: return 15
        case 5.1...7: return 25
        case 7.1...10: return 35
        default: return 40
        }
    }

    static func scoreHumidity(_ humidity: Double, skinType: SkinType) -> Int {
        let baseScore: Int
        switch humidity {
        case 0...20: baseScore = 20
        case 20.1...30: baseScore = 15
        case 30.1...40: baseScore = 10
        case 40.1...70: baseScore = 0
        case 70.1...85: baseScore = 5
        default: baseScore = 8
        }

        if skinType == .dry && humidity < 40 {
            return min(baseScore + 3, 20)
        }
        if skinType == .oily && humidity > 70 {
            return min(baseScore + 3, 20)
        }
        return baseScore
    }

    static func scoreTemperature(_ temp: Double) -> Int {
        switch temp {
        case ..<5: return 15
        case 5...10: return 10
        case 10.1...28: return 0
        case 28.1...32: return 10
        default: return 15
        }
    }

    static func scoreWind(_ windKmh: Double) -> Int {
        switch windKmh {
        case 0...15: return 0
        case 15.1...25: return 3
        case 25.1...40: return 5
        default: return 10
        }
    }

    static func scoreAirQuality(_ aqi: Int) -> Int {
        switch aqi {
        case 0...50: return 0
        case 51...100: return 3
        case 101...150: return 7
        default: return 10
        }
    }

    static func scoreSkinProfile(_ profile: SkinProfile, weather: DailyWeatherSnapshot) -> Int {
        var score = 0
        switch profile.sensitivity {
        case .none: score += 0
        case .mild: score += 2
        case .moderate: score += 5
        case .reactive: score += 8
        }

        if profile.skinType == .dry && weather.humidityPercent < 40 {
            score += 2
        }
        if profile.skinType == .oily && weather.temperatureCelsius > 28 {
            score += 2
        }
        if profile.primaryConcerns.contains(.redness) && weather.uvIndex > 5 {
            score += 2
        }

        return min(score, 15)
    }

    static func scoreScanTrend(_ context: ScanContext) -> Int {
        var score = 0
        if context.hasRecentIrritation { score += 3 }
        if context.hasRecentBreakouts { score += 2 }
        if context.hasRecentDryness { score += 2 }
        if !context.worseningZones.isEmpty { score += 1 }
        if context.daysSinceLastScan > 7 { score += 1 }
        return min(score, 8)
    }

    static func scoreRoutine(_ context: RoutineContext) -> Int {
        var score = 0
        if context.adherenceThisWeek < 0.5 { score += 2 }
        if context.recentlyUsedExfoliant && !context.spfPresentInRoutine { score += 3 }
        if context.recentlyUsedRetinol { score += 1 }
        return min(score, 5)
    }
}

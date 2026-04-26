import Foundation

// MARK: - Advice Copy Engine

enum AdviceCopyEngine {

    struct CopyInputs {
        let riskBreakdown: SkinRiskScorer.RiskBreakdown
        let timeOfDay: TimeOfDay
        let weather: DailyWeatherSnapshot
        let airQuality: AirQualitySnapshot
        let skinProfile: SkinProfile
        let scanContext: ScanContext
        let routineContext: RoutineContext
    }

    struct GeneratedCopy {
        let primaryAdvice: String
        let secondaryAdvice: String
        let actions: [SkinAdviceAction]
        let affectedZones: [ZoneType]
        let factors: [EnvironmentFactor]
        let dataSources: [String]
    }

    static func generate(inputs: CopyInputs) -> GeneratedCopy {
        let primary = buildPrimaryAdvice(inputs: inputs)
        let secondary = buildSecondaryAdvice(inputs: inputs)
        let actions = buildActions(inputs: inputs)
        let zones = determineAffectedZones(inputs: inputs)
        let factors = buildEnvironmentFactors(inputs: inputs)
        let sources = buildDataSources(inputs: inputs)

        return GeneratedCopy(
            primaryAdvice: primary,
            secondaryAdvice: secondary,
            actions: actions,
            affectedZones: zones,
            factors: factors,
            dataSources: sources
        )
    }

    // MARK: - Primary Advice

    private static func buildPrimaryAdvice(inputs: CopyInputs) -> String {
        let bd = inputs.riskBreakdown
        let time = inputs.timeOfDay
        let weather = inputs.weather

        // UV-dominant risk
        if bd.uvScore >= 25 {
            switch time {
            case .morning:
                return "UV is high today — apply SPF 50 and reapply around midday."
            case .midday:
                return "UV is still strong — reapply SPF now if you have been outside."
            case .evening, .night:
                return "UV was high today — check your skin and prioritise barrier repair tonight."
            }
        }

        // Dryness-dominant risk
        if bd.humidityScore >= 15 || (inputs.skinProfile.skinType == .dry && weather.humidityPercent < 30) {
            return "Low humidity may increase dryness. Add a barrier-supporting moisturiser."
        }

        // Heat-dominant risk
        if bd.temperatureScore >= 10 {
            if inputs.skinProfile.primaryConcerns.contains(.breakouts) {
                return "Heat and sweat may trigger breakouts. Keep your routine simple and light."
            }
            return "High temperatures can increase oil and irritation. Stay cool and hydrated."
        }

        // Irritation-dominant risk
        if inputs.scanContext.hasRecentIrritation {
            return "Recent irritation detected. Simplify your routine and focus on soothing products."
        }

        // Breakout-dominant risk (from scan or routine)
        if bd.scanTrendScore >= 2 && inputs.scanContext.hasRecentBreakouts {
            return "Breakout risk is elevated. Keep the routine simple and avoid heavy products."
        }

        // Air quality dominant
        if bd.airQualityScore >= 7 {
            return "Poor air quality today — cleanse thoroughly this evening and protect your barrier."
        }

        // Retinol / exfoliant caution
        if (inputs.routineContext.recentlyUsedRetinol || inputs.routineContext.recentlyUsedExfoliant) && time == .morning {
            return "You used an exfoliant recently — prioritise SPF and avoid strong actives this morning."
        }

        // Wind-dominant
        if bd.windScore >= 5 {
            return "Strong winds can strip moisture. Layer a protective moisturiser and consider SPF."
        }

        // Low adherence warning
        if bd.routineScore >= 2 && inputs.routineContext.adherenceThisWeek < 0.5 {
            return "Routine consistency is low. A simple, regular routine helps skin stay balanced."
        }

        // Default time-of-day advice
        switch time {
        case .morning:
            return "Your skin is looking steady. Stick to your routine and use SPF."
        case .midday:
            return "Skin is on track. Reapply SPF if you have been outside."
        case .evening:
            return "Good time to support your skin barrier overnight."
        case .night:
            return "Rest is when skin repairs itself. Keep your evening routine gentle."
        }
    }

    // MARK: - Secondary Advice

    private static func buildSecondaryAdvice(inputs: CopyInputs) -> String {
        let bd = inputs.riskBreakdown
        let time = inputs.timeOfDay
        var parts: [String] = []

        if bd.uvScore >= 15 && bd.uvScore < 25 {
            parts.append("UV is moderate — SPF 30+ is recommended.")
        }
        if bd.humidityScore >= 10 && inputs.skinProfile.skinType != .dry {
            parts.append("Air is dry — consider a humidifier indoors.")
        }
        if bd.temperatureScore >= 10 && time == .evening {
            parts.append("Cool down before applying evening products.")
        }
        if inputs.airQuality.aqi > 100 {
            parts.append("Air quality is poor — avoid outdoor workouts if possible.")
        }
        if inputs.scanContext.daysSinceLastScan > 3 {
            parts.append("A quick scan would help track any changes.")
        }
        if inputs.routineContext.recentlyUsedExfoliant && time == .evening {
            parts.append("You used an exfoliant recently — go gentle tonight.")
        }

        if parts.isEmpty {
            switch time {
            case .morning:
                return "Consistency matters more than perfection."
            case .midday:
                return "Keep hydrated and avoid touching your face."
            case .evening:
                return "A simple routine done daily beats a complex one done rarely."
            case .night:
                return "Clean pillowcases make a bigger difference than you might expect."
            }
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Actions

    private static func buildActions(inputs: CopyInputs) -> [SkinAdviceAction] {
        var actions: [SkinAdviceAction] = []
        let time = inputs.timeOfDay
        let weather = inputs.weather
        let bd = inputs.riskBreakdown

        // Time-of-day base actions
        switch time {
        case .morning:
            if bd.uvScore >= 15 {
                actions.append(SkinAdviceAction(
                    title: "Apply SPF",
                    detail: bd.uvScore >= 25 ? "Use SPF 50+ before going outside" : "Use SPF 30+ this morning",
                    icon: "sun.max.fill",
                    priority: .essential,
                    timeContext: .morning
                ))
            }
            if inputs.skinProfile.skinType == .dry || bd.humidityScore >= 10 {
                actions.append(SkinAdviceAction(
                    title: "Layer moisturiser",
                    detail: "Seal in hydration before leaving home",
                    icon: "drop.fill",
                    priority: .recommended,
                    timeContext: .morning
                ))
            }
            if inputs.routineContext.recentlyUsedRetinol {
                actions.append(SkinAdviceAction(
                    title: "Skip strong actives",
                    detail: "Let your skin recover before using acids or retinol again",
                    icon: "shield.fill",
                    priority: .recommended,
                    timeContext: .morning
                ))
            }
        case .midday:
            if bd.uvScore >= 15 {
                actions.append(SkinAdviceAction(
                    title: "Reapply SPF",
                    detail: "Especially if you have been sweating or outdoors",
                    icon: "sun.max.fill",
                    priority: .essential,
                    timeContext: .midday
                ))
            }
            if weather.temperatureCelsius > 28 {
                actions.append(SkinAdviceAction(
                    title: "Blot and refresh",
                    detail: "Gently remove excess oil without stripping skin",
                    icon: "wind",
                    priority: .recommended,
                    timeContext: .midday
                ))
            }
        case .evening:
            if inputs.scanContext.hasRecentIrritation || inputs.scanContext.hasRecentDryness {
                actions.append(SkinAdviceAction(
                    title: "Soothe and repair",
                    detail: "Focus on barrier-supporting ingredients tonight",
                    icon: "heart.fill",
                    priority: .essential,
                    timeContext: .evening
                ))
            }
            if inputs.airQuality.aqi > 100 {
                actions.append(SkinAdviceAction(
                    title: "Double cleanse",
                    detail: "Remove pollution particles gently but thoroughly",
                    icon: "sparkles",
                    priority: .recommended,
                    timeContext: .evening
                ))
            }
            if !inputs.routineContext.recentlyUsedExfoliant && !inputs.scanContext.hasRecentIrritation {
                actions.append(SkinAdviceAction(
                    title: "Consider an active",
                    detail: "Skin is calm — a good night for targeted treatment",
                    icon: "star.fill",
                    priority: .optional,
                    timeContext: .evening
                ))
            }
        case .night:
            actions.append(SkinAdviceAction(
                title: "Get good sleep",
                detail: "Skin repairs most during deep sleep cycles",
                icon: "moon.fill",
                priority: .recommended,
                timeContext: .night
            ))
        }

        // Environmental additions
        if bd.windScore >= 5 && time != .night {
            actions.append(SkinAdviceAction(
                title: "Protect from wind",
                detail: "A occlusive layer helps prevent moisture loss",
                icon: "wind",
                priority: .recommended,
                timeContext: time
            ))
        }
        if bd.airQualityScore >= 7 && time == .evening {
            actions.append(SkinAdviceAction(
                title: "Rinse after outdoor time",
                detail: "Wash away particulate matter before bed",
                icon: "drop.fill",
                priority: .recommended,
                timeContext: .evening
            ))
        }

        return actions.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }

    // MARK: - Affected Zones

    private static func determineAffectedZones(inputs: CopyInputs) -> [ZoneType] {
        var zones = Set<ZoneType>()

        if inputs.scanContext.hasRecentBreakouts {
            zones.insert(.chinJaw)
            zones.insert(.forehead)
        }
        if inputs.scanContext.hasRecentDryness {
            zones.insert(.leftCheek)
            zones.insert(.rightCheek)
        }
        if inputs.scanContext.hasRecentIrritation {
            zones.formUnion(inputs.scanContext.worseningZones)
        }
        if inputs.weather.uvIndex > 5 {
            zones.insert(.nose)
            zones.insert(.forehead)
        }
        if inputs.weather.windSpeedKmh > 25 {
            zones.insert(.leftCheek)
            zones.insert(.rightCheek)
        }

        if zones.isEmpty {
            return [.forehead, .nose, .leftCheek, .rightCheek, .chinJaw]
        }
        return Array(zones).sorted { $0.rawValue < $1.rawValue }
    }

    // MARK: - Environment Factors

    private static func buildEnvironmentFactors(inputs: CopyInputs) -> [EnvironmentFactor] {
        var factors: [EnvironmentFactor] = []
        let weather = inputs.weather
        let aq = inputs.airQuality

        // UV
        if weather.uvIndex > 5 {
            factors.append(EnvironmentFactor(
                kind: .uv,
                severity: weather.uvIndex > 8 ? .severe : weather.uvIndex > 6 ? .significant : .moderate,
                description: "UV index is \(String(format: "%.1f", weather.uvIndex))",
                recommendation: "Use broad-spectrum SPF and seek shade during peak hours."
            ))
        }

        // Humidity
        if weather.humidityPercent < 30 {
            factors.append(EnvironmentFactor(
                kind: .humidity,
                severity: weather.humidityPercent < 20 ? .severe : .significant,
                description: "Humidity is low at \(Int(weather.humidityPercent))%",
                recommendation: "Increase moisturiser layers and consider a humidifier."
            ))
        } else if weather.humidityPercent > 85 {
            factors.append(EnvironmentFactor(
                kind: .humidity,
                severity: .moderate,
                description: "Humidity is high at \(Int(weather.humidityPercent))%",
                recommendation: "Lightweight products may feel more comfortable today."
            ))
        }

        // Temperature
        if weather.temperatureCelsius > 32 {
            factors.append(EnvironmentFactor(
                kind: .temperature,
                severity: .significant,
                description: "Temperature is high at \(Int(weather.temperatureCelsius))°C",
                recommendation: "Stay cool, hydrated, and avoid heavy occlusive products."
            ))
        } else if weather.temperatureCelsius < 5 {
            factors.append(EnvironmentFactor(
                kind: .temperature,
                severity: .significant,
                description: "Temperature is low at \(Int(weather.temperatureCelsius))°C",
                recommendation: "Protect exposed skin and add an extra moisturiser layer."
            ))
        }

        // Wind
        if weather.windSpeedKmh > 25 {
            factors.append(EnvironmentFactor(
                kind: .wind,
                severity: weather.windSpeedKmh > 40 ? .significant : .moderate,
                description: "Wind speed is \(Int(weather.windSpeedKmh)) km/h",
                recommendation: "Wind can strip moisture — use a protective balm on exposed areas."
            ))
        }

        // Air Quality
        if aq.aqi > 50 {
            factors.append(EnvironmentFactor(
                kind: .airQuality,
                severity: aq.aqi > 150 ? .severe : aq.aqi > 100 ? .significant : .moderate,
                description: "Air quality index is \(aq.aqi)",
                recommendation: "Limit outdoor exposure and cleanse thoroughly this evening."
            ))
        }

        return factors
    }

    // MARK: - Data Sources

    private static func buildDataSources(inputs: CopyInputs) -> [String] {
        var sources: [String] = []
        sources.append("Current weather data")
        if inputs.airQuality.aqi > 0 {
            sources.append("Air quality index")
        }
        if inputs.scanContext.latestScanDate != nil {
            sources.append("Recent skin scan")
        }
        if !inputs.routineContext.adherenceThisWeek.isZero {
            sources.append("Routine adherence")
        }
        sources.append("Skin profile")
        sources.append("Time of day")
        return sources
    }
}

// MARK: - Action Priority Sorting

private extension ActionPriority {
    var sortOrder: Int {
        switch self {
        case .essential: return 0
        case .recommended: return 1
        case .optional: return 2
        }
    }
}

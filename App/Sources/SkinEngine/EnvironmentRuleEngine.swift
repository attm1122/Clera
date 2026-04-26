import Foundation

// MARK: - Environment Rule Engine

enum EnvironmentRuleEngine {

    static func evaluate(context: SkinContext) -> [SkinRecommendation] {
        var recommendations: [SkinRecommendation] = []

        guard let weather = context.weatherSnapshot else {
            return recommendations
        }

        let uv = weather.uvIndex
        let humidity = weather.humidityPercent
        let temp = weather.temperatureCelsius
        let aqi = context.airQualitySnapshot?.aqi ?? 0

        // UV rules
        if uv >= 8 {
            recommendations.append(SkinRecommendation(
                title: "Strong UV protection needed",
                body: "UV index is very high today. Use broad-spectrum SPF 50+, reapply every 2 hours outdoors, and seek shade during peak hours.",
                action: "Apply SPF 50+",
                category: .environment,
                priority: .high,
                confidence: .high,
                zones: [.forehead, .nose, .leftCheek, .rightCheek],
                durationDays: 1,
                createdAt: .now
            ))
        } else if uv >= 6 {
            recommendations.append(SkinRecommendation(
                title: "High UV — reapply sunscreen",
                body: "UV is strong today. Apply SPF 30+ or higher this morning and reapply around midday if you are outside.",
                action: "Apply SPF",
                category: .environment,
                priority: .high,
                confidence: .high,
                zones: [.forehead, .nose],
                durationDays: 1,
                createdAt: .now
            ))
        } else if uv >= 3 {
            recommendations.append(SkinRecommendation(
                title: "Moderate UV — use sunscreen",
                body: "UV is moderate today. SPF is still your most important step this morning.",
                action: "Apply SPF",
                category: .environment,
                priority: .medium,
                confidence: .high,
                zones: [.forehead, .nose],
                durationDays: 1,
                createdAt: .now
            ))
        }

        // Humidity rules
        if humidity < 30 {
            recommendations.append(SkinRecommendation(
                title: "Very dry air — protect your barrier",
                body: "Humidity is very low. Add a barrier-supporting moisturiser and consider a humidifier indoors.",
                action: "Layer moisturiser",
                category: .environment,
                priority: .high,
                confidence: .high,
                zones: [.leftCheek, .rightCheek, .forehead],
                durationDays: 1,
                createdAt: .now
            ))
        } else if humidity < 40 {
            recommendations.append(SkinRecommendation(
                title: "Low humidity — add moisture",
                body: "Air is dry today. A hydrating serum or thicker moisturiser may help your skin stay comfortable.",
                action: "Add hydration",
                category: .environment,
                priority: .medium,
                confidence: .high,
                zones: [.leftCheek, .rightCheek],
                durationDays: 1,
                createdAt: .now
            ))
        }

        // AQI rules
        if aqi > 100 {
            recommendations.append(SkinRecommendation(
                title: "Poor air quality — cleanse thoroughly",
                body: "Air quality is poor. Rinse your face after being outside and use your evening cleanse to remove particulates.",
                action: "Double cleanse tonight",
                category: .environment,
                priority: .high,
                confidence: .medium,
                zones: [.forehead, .nose, .leftCheek, .rightCheek, .chinJaw],
                durationDays: 1,
                createdAt: .now
            ))
        } else if aqi > 75 {
            recommendations.append(SkinRecommendation(
                title: "Moderate pollution — protect your barrier",
                body: "Air quality is moderate. A good moisturiser helps form a protective layer against environmental particulates.",
                action: "Protect barrier",
                category: .environment,
                priority: .medium,
                confidence: .medium,
                zones: [.forehead, .nose],
                durationDays: 1,
                createdAt: .now
            ))
        }

        // Temperature rules
        if temp > 28 {
            recommendations.append(SkinRecommendation(
                title: "Hot weather — manage sweat and oil",
                body: "High temperatures can increase oil and sweat. Keep your routine light and avoid heavy occlusive products.",
                action: "Lighten routine",
                category: .environment,
                priority: .medium,
                confidence: .high,
                zones: [.forehead, .nose, .chinJaw],
                durationDays: 1,
                createdAt: .now
            ))
        } else if temp < 5 {
            recommendations.append(SkinRecommendation(
                title: "Cold weather — add protection",
                body: "Cold air strips moisture. Add an extra layer of moisturiser and protect exposed skin when outside.",
                action: "Add moisturiser layer",
                category: .environment,
                priority: .medium,
                confidence: .high,
                zones: [.leftCheek, .rightCheek, .forehead],
                durationDays: 1,
                createdAt: .now
            ))
        }

        // Wind rules
        if weather.windSpeedKmh > 25 {
            recommendations.append(SkinRecommendation(
                title: "Windy conditions — protect exposed skin",
                body: "Strong wind can strip moisture from your skin. A protective moisturiser or balm helps prevent dryness.",
                action: "Protect from wind",
                category: .environment,
                priority: .medium,
                confidence: .medium,
                zones: [.leftCheek, .rightCheek, .forehead],
                durationDays: 1,
                createdAt: .now
            ))
        }

        return recommendations
    }
}

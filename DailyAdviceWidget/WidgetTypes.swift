import Foundation

// MARK: - Widget-local type definitions
// These mirror the app types exactly for JSON compatibility.

enum TimeOfDay: String, Codable, CaseIterable, Sendable {
    case morning, midday, evening, night

    var displayName: String {
        switch self {
        case .morning: "Morning"
        case .midday: "Midday"
        case .evening: "Evening"
        case .night: "Tonight"
        }
    }

    var adviceContext: String {
        switch self {
        case .morning: "Prepare your skin for the day ahead."
        case .midday: "Protect and refresh through the afternoon."
        case .evening: "Help your skin recover overnight."
        case .night: "Rest and repair while you sleep."
        }
    }
}

enum SkinRiskLevel: String, Codable, CaseIterable, Sendable {
    case low, moderate, high, extreme

    var displayName: String {
        switch self {
        case .low: "Low Risk"
        case .moderate: "Moderate Risk"
        case .high: "High Risk"
        case .extreme: "Extreme Risk"
        }
    }

    var sfSymbol: String {
        switch self {
        case .low: "checkmark.shield.fill"
        case .moderate: "exclamationmark.triangle.fill"
        case .high: "exclamationmark.octagon.fill"
        case .extreme: "xmark.octagon.fill"
        }
    }
}

enum WeatherCondition: String, Codable, CaseIterable, Sendable {
    case clear, partlyCloudy, cloudy, rain, snow, thunderstorm, fog, unknown
}

enum EnvironmentFactorKind: String, Codable, CaseIterable, Sendable {
    case uv, humidity, temperature, wind, airQuality
}

enum FactorSeverity: String, Codable, CaseIterable, Sendable {
    case mild, moderate, significant, severe
}

enum ActionPriority: String, Codable, CaseIterable, Sendable {
    case essential, recommended, optional
}

enum ZoneType: String, Codable, CaseIterable, Sendable {
    case forehead, nose, leftCheek, rightCheek, chinJaw

    var displayName: String {
        switch self {
        case .forehead: "Forehead"
        case .nose: "Nose"
        case .leftCheek: "Left Cheek"
        case .rightCheek: "Right Cheek"
        case .chinJaw: "Chin & Jaw"
        }
    }
}

enum InsightConfidence: String, Codable, CaseIterable, Sendable {
    case high, moderate, low

    var displayName: String {
        switch self {
        case .high: "Confident"
        case .moderate: "Fairly confident"
        case .low: "Still learning"
        }
    }
}

// MARK: - Data Structs

struct DailyWeatherSnapshot: Codable, Equatable, Sendable {
    var uvIndex: Double
    var temperatureCelsius: Double
    var humidityPercent: Double
    var windSpeedKmh: Double
    var condition: WeatherCondition
}

struct AirQualitySnapshot: Codable, Equatable, Sendable {
    var aqi: Int
    var pm25: Double?
    var dominantPollutant: String?
}

struct EnvironmentFactor: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var kind: EnvironmentFactorKind
    var severity: FactorSeverity
    var description: String
    var recommendation: String
}

struct SkinAdviceAction: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var title: String
    var detail: String
    var icon: String
    var priority: ActionPriority
    var timeContext: TimeOfDay
}

struct ScanContext: Codable, Equatable, Sendable {
    var daysSinceLastScan: Int
    var latestScanDate: Date?
    var hasRecentIrritation: Bool
    var hasRecentBreakouts: Bool
    var hasRecentDryness: Bool
    var worseningZones: [ZoneType]
}

struct RoutineContext: Codable, Equatable, Sendable {
    var adherenceThisWeek: Double
    var missedDaysCount: Int
    var recentlyUsedExfoliant: Bool
    var recentlyUsedRetinol: Bool
    var spfPresentInRoutine: Bool
}

struct DailySkinAdviceResult: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var generatedAt: Date
    var timeOfDay: TimeOfDay
    var riskLevel: SkinRiskLevel
    var riskScore: Int
    var primaryAdvice: String
    var secondaryAdvice: String
    var recommendedActions: [SkinAdviceAction]
    var affectedZones: [ZoneType]
    var confidence: InsightConfidence
    var dataSourcesUsed: [String]
    var weatherSnapshot: DailyWeatherSnapshot?
    var airQualitySnapshot: AirQualitySnapshot?
    var environmentFactors: [EnvironmentFactor]
    var scanContext: ScanContext?
    var routineContext: RoutineContext?
}

struct DailyAdviceWidgetPayload: Codable, Equatable, Sendable {
    var version: Int = 1
    var generatedAt: Date
    var result: DailySkinAdviceResult?
    var history: [DailySkinAdviceResult]
}

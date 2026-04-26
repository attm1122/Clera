import Foundation

// MARK: - Time of Day

enum TimeOfDay: String, Codable, CaseIterable, Sendable {
    case morning, midday, evening, night

    static func current() -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .midday
        case 17..<22: return .evening
        default: return .night
        }
    }

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

// MARK: - Risk Level

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

    var colorHex: UInt64 {
        switch self {
        case .low: 0x99A744
        case .moderate: 0xD4A017
        case .high: 0xC75B39
        case .extreme: 0x8B3A3A
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

    static func from(score: Int) -> SkinRiskLevel {
        switch score {
        case 0...25: return .low
        case 26...50: return .moderate
        case 51...75: return .high
        default: return .extreme
        }
    }
}

// MARK: - Environment Snapshots

struct DailyWeatherSnapshot: Codable, Equatable, Sendable {
    var uvIndex: Double
    var temperatureCelsius: Double
    var humidityPercent: Double
    var windSpeedKmh: Double
    var condition: WeatherCondition
}

enum WeatherCondition: String, Codable, CaseIterable, Sendable {
    case clear, partlyCloudy, cloudy, rain, snow, thunderstorm, fog, unknown
}

struct AirQualitySnapshot: Codable, Equatable, Sendable {
    var aqi: Int
    var pm25: Double?
    var dominantPollutant: String?
}

// MARK: - Environment Factor

struct EnvironmentFactor: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var kind: EnvironmentFactorKind
    var severity: FactorSeverity
    var description: String
    var recommendation: String
}

enum EnvironmentFactorKind: String, Codable, CaseIterable, Sendable {
    case uv, humidity, temperature, wind, airQuality
}

enum FactorSeverity: String, Codable, CaseIterable, Sendable {
    case mild, moderate, significant, severe

    var scoreWeight: Int {
        switch self {
        case .mild: 1
        case .moderate: 2
        case .significant: 3
        case .severe: 4
        }
    }
}

// MARK: - Skin Advice Action

struct SkinAdviceAction: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var title: String
    var detail: String
    var icon: String
    var priority: ActionPriority
    var timeContext: TimeOfDay
}

enum ActionPriority: String, Codable, CaseIterable, Sendable {
    case essential, recommended, optional
}

// MARK: - Daily Skin Advice Result

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

// MARK: - Context Helpers

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

// MARK: - Widget Payload

struct DailyAdviceWidgetPayload: Codable, Equatable, Sendable {
    var version: Int = 1
    var generatedAt: Date
    var result: DailySkinAdviceResult?
    var history: [DailySkinAdviceResult]
}

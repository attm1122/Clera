import Foundation

/// Generates environmental context signals that may correlate with skin changes.
/// Ready for WeatherKit integration via `WeatherServiceAdapter`.
enum EnvironmentalContextEngine {

    /// Minimum scans before showing environmental context.
    static let minimumScans = 3

    /// Analyzes recent sessions and generates environmental signals.
    /// Uses the provided `weatherAdapter` to fetch real or mock weather data.
    static func analyze(
        sessions: [ScanSession],
        weatherAdapter: WeatherServiceAdapter = PlaceholderWeatherAdapter()
    ) -> [EnvironmentalSignal] {

        guard sessions.count >= minimumScans else { return [] }

        let calendar = Calendar.current
        let sorted = sessions.sorted(by: { $0.createdAt < $1.createdAt })
        guard let earliest = sorted.first?.createdAt,
              let latest = sorted.last?.createdAt else { return [] }

        let weatherData = runAsyncAndBlock {
            try? await weatherAdapter.fetchWeather(for: earliest...latest)
        } ?? []

        guard !weatherData.isEmpty else { return [] }

        var signals: [EnvironmentalSignal] = []

        // Group weather by week
        let weatherByWeek = Dictionary(grouping: weatherData) { day in
            calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: day.date)
        }

        for (_, weekWeather) in weatherByWeek {
            let avgUV = weekWeather.map(\.uvIndex).reduce(0, +) / Double(weekWeather.count)
            let avgHumidity = weekWeather.map(\.humidity).reduce(0, +) / Double(weekWeather.count)
            let avgTemp = weekWeather.map(\.temperature).reduce(0, +) / Double(weekWeather.count)
            let maxAQI = weekWeather.map(\.airQualityIndex).max() ?? 0

            let dates = weekWeather.map(\.date)
            guard let start = dates.min(), let end = dates.max() else { continue }

            // High UV signal
            if avgUV >= 6 {
                signals.append(EnvironmentalSignal(
                    type: .highUV,
                    dateRange: .init(start: start, end: end),
                    message: CleraCopy.Environmental.highUV,
                    confidence: .low
                ))
            }

            // Low humidity signal
            if avgHumidity < 30 {
                signals.append(EnvironmentalSignal(
                    type: .lowHumidity,
                    dateRange: .init(start: start, end: end),
                    message: CleraCopy.Environmental.lowHumidity,
                    confidence: .low
                ))
            }

            // Poor air quality
            if maxAQI > 100 {
                signals.append(EnvironmentalSignal(
                    type: .poorAirQuality,
                    dateRange: .init(start: start, end: end),
                    message: CleraCopy.Environmental.poorAirQuality,
                    confidence: .low
                ))
            }

            // Heat spike
            if avgTemp > 30 {
                signals.append(EnvironmentalSignal(
                    type: .heatSpike,
                    dateRange: .init(start: start, end: end),
                    message: CleraCopy.Environmental.heatSpike,
                    confidence: .low
                ))
            }
        }

        return signals
    }

    /// Correlates environmental signals with skin changes to generate cautious messages.
    static func correlate(
        signals: [EnvironmentalSignal],
        sessions: [ScanSession]
    ) -> [EnvironmentalSignal] {
        guard !signals.isEmpty, sessions.count >= 2 else { return signals }

        let sortedSessions = sessions.sorted(by: { $0.createdAt > $1.createdAt })
        let latest = sortedSessions[0]
        let previous = sortedSessions[1]

        return signals.map { signal in
            var updated = signal

            // Check if dryness increased during low humidity
            if signal.type == .lowHumidity {
                let drynessIncreased = latest.skinMap.zones.contains { zone in
                    let prevZone = previous.skinMap.zones.first(where: { $0.zoneType == zone.zoneType })
                    return severityScore(zone.status.dryness) > severityScore(prevZone?.status.dryness ?? .none)
                }
                if drynessIncreased {
                    updated.message = CleraCopy.Environmental.lowHumidityDrynessLink
                }
            }

            // Check if breakouts increased during heat spike
            if signal.type == .heatSpike {
                let breakoutsIncreased = latest.skinMap.zones.contains { zone in
                    let prevZone = previous.skinMap.zones.first(where: { $0.zoneType == zone.zoneType })
                    return severityScore(zone.status.breakouts) > severityScore(prevZone?.status.breakouts ?? .none)
                }
                if breakoutsIncreased {
                    updated.message = CleraCopy.Environmental.heatBreakoutLink
                }
            }

            return updated
        }
    }
}

// MARK: - Helpers

private func severityScore(_ severity: ZoneSeverity) -> Int {
    switch severity {
    case .none: return 0
    case .low: return 1
    case .moderate: return 2
    case .high: return 3
    }
}

// MARK: - Async Helper for Synchronous Context

private func runAsyncAndBlock<T: Sendable>(_ operation: @escaping @Sendable () async -> T?) -> T? {
    let semaphore = DispatchSemaphore(value: 0)
    let box = ResultBox<T>()
    Task {
        box.value = await operation()
        semaphore.signal()
    }
    semaphore.wait()
    return box.value
}

private final class ResultBox<T>: @unchecked Sendable {
    var value: T?
}

// MARK: - Weather Data Placeholder

/// Placeholder for weather data. Replace with WeatherKit `Weather` or API response.
struct DailyWeather: Codable, Equatable, Sendable {
    var date: Date
    var uvIndex: Double
    var humidity: Double // 0-100
    var temperature: Double // Celsius
    var airQualityIndex: Int
}

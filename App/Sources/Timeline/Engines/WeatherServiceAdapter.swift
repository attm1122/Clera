import Foundation

// MARK: - Weather Service Protocol

/// Abstracts weather data sources so Clera can use WeatherKit on device
/// or fall back to a placeholder/mock implementation for testing.
protocol WeatherServiceAdapter: Sendable {
    /// Fetches historical weather data for the given date range.
    func fetchWeather(for dateRange: ClosedRange<Date>) async throws -> [DailyWeather]
}

// MARK: - Placeholder Implementation

/// Placeholder adapter that returns empty data.
/// Used when WeatherKit is not available or the user has not granted location access.
struct PlaceholderWeatherAdapter: WeatherServiceAdapter {
    func fetchWeather(for dateRange: ClosedRange<Date>) async throws -> [DailyWeather] {
        []
    }
}

// MARK: - Mock Implementation (Testing)

/// Deterministic mock weather adapter for unit tests and simulator demos.
struct MockWeatherAdapter: WeatherServiceAdapter {
    let scenario: WeatherScenario

    enum WeatherScenario {
        case highUV
        case lowHumidity
        case heatSpike
        case poorAirQuality
        case mixed
    }

    func fetchWeather(for dateRange: ClosedRange<Date>) async throws -> [DailyWeather] {
        let calendar = Calendar.current
        var weather: [DailyWeather] = []
        var date = dateRange.lowerBound

        while date <= dateRange.upperBound {
            let day = calendar.component(.day, from: date)
            let w = weatherForDay(day: day)
            weather.append(w)
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }

        return weather
    }

    private func weatherForDay(day: Int) -> DailyWeather {
        switch scenario {
        case .highUV:
            return DailyWeather(
                date: Calendar.current.date(byAdding: .day, value: day, to: .now)!,
                uvIndex: 8.0 + Double(day % 3),
                humidity: 50,
                temperature: 25,
                airQualityIndex: 40
            )
        case .lowHumidity:
            return DailyWeather(
                date: Calendar.current.date(byAdding: .day, value: day, to: .now)!,
                uvIndex: 4,
                humidity: 20 + Double(day % 5),
                temperature: 22,
                airQualityIndex: 35
            )
        case .heatSpike:
            return DailyWeather(
                date: Calendar.current.date(byAdding: .day, value: day, to: .now)!,
                uvIndex: 6,
                humidity: 45,
                temperature: 32 + Double(day % 4),
                airQualityIndex: 50
            )
        case .poorAirQuality:
            return DailyWeather(
                date: Calendar.current.date(byAdding: .day, value: day, to: .now)!,
                uvIndex: 5,
                humidity: 55,
                temperature: 24,
                airQualityIndex: 120 + day * 5
            )
        case .mixed:
            return DailyWeather(
                date: Calendar.current.date(byAdding: .day, value: day, to: .now)!,
                uvIndex: 3.0 + Double(day % 6),
                humidity: 30 + Double(day % 40),
                temperature: 18 + Double(day % 15),
                airQualityIndex: 30 + day * 3
            )
        }
    }
}

// WeatherKit adapter available in git history when ready for integration.

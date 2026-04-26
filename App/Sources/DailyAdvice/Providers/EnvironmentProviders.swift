import Foundation

// MARK: - Protocols

protocol WeatherProvider: Sendable {
    func fetchCurrent() async -> DailyWeatherSnapshot
}

protocol UVProvider: Sendable {
    func fetchCurrentUV() async -> Double
}

protocol AirQualityProvider: Sendable {
    func fetchCurrentAQI() async -> AirQualitySnapshot
}

// MARK: - Composite Provider

struct CompositeEnvironmentProvider: Sendable {
    let weather: any WeatherProvider
    let uv: any UVProvider
    let airQuality: any AirQualityProvider

    func fetchAll() async -> (DailyWeatherSnapshot, Double, AirQualitySnapshot) {
        async let weatherSnapshot = weather.fetchCurrent()
        async let uvIndex = uv.fetchCurrentUV()
        async let aqSnapshot = airQuality.fetchCurrentAQI()
        return await (weatherSnapshot, uvIndex, aqSnapshot)
    }
}

// MARK: - Mock Providers

struct MockWeatherProvider: WeatherProvider {
    let scenario: MockWeatherScenario

    enum MockWeatherScenario: String, CaseIterable, Sendable {
        case highUV, lowHumidity, heatSpike, poorAirQuality, highWind, coldDry, pleasant, rainy
    }

    func fetchCurrent() async -> DailyWeatherSnapshot {
        switch scenario {
        case .highUV:
            return DailyWeatherSnapshot(
                uvIndex: 9.5,
                temperatureCelsius: 28,
                humidityPercent: 45,
                windSpeedKmh: 8,
                condition: .clear
            )
        case .lowHumidity:
            return DailyWeatherSnapshot(
                uvIndex: 3.0,
                temperatureCelsius: 18,
                humidityPercent: 18,
                windSpeedKmh: 12,
                condition: .clear
            )
        case .heatSpike:
            return DailyWeatherSnapshot(
                uvIndex: 7.0,
                temperatureCelsius: 36,
                humidityPercent: 65,
                windSpeedKmh: 5,
                condition: .partlyCloudy
            )
        case .poorAirQuality:
            return DailyWeatherSnapshot(
                uvIndex: 4.0,
                temperatureCelsius: 22,
                humidityPercent: 55,
                windSpeedKmh: 6,
                condition: .cloudy
            )
        case .highWind:
            return DailyWeatherSnapshot(
                uvIndex: 5.0,
                temperatureCelsius: 20,
                humidityPercent: 40,
                windSpeedKmh: 55,
                condition: .partlyCloudy
            )
        case .coldDry:
            return DailyWeatherSnapshot(
                uvIndex: 1.5,
                temperatureCelsius: 2,
                humidityPercent: 25,
                windSpeedKmh: 20,
                condition: .clear
            )
        case .pleasant:
            return DailyWeatherSnapshot(
                uvIndex: 3.5,
                temperatureCelsius: 22,
                humidityPercent: 55,
                windSpeedKmh: 10,
                condition: .clear
            )
        case .rainy:
            return DailyWeatherSnapshot(
                uvIndex: 1.0,
                temperatureCelsius: 15,
                humidityPercent: 85,
                windSpeedKmh: 15,
                condition: .rain
            )
        }
    }
}

struct MockUVProvider: UVProvider {
    let scenario: MockWeatherProvider.MockWeatherScenario

    func fetchCurrentUV() async -> Double {
        let weather = await MockWeatherProvider(scenario: scenario).fetchCurrent()
        return weather.uvIndex
    }
}

struct MockAirQualityProvider: AirQualityProvider {
    let scenario: MockWeatherProvider.MockWeatherScenario

    func fetchCurrentAQI() async -> AirQualitySnapshot {
        switch scenario {
        case .poorAirQuality:
            return AirQualitySnapshot(aqi: 165, pm25: 65.0, dominantPollutant: "PM2.5")
        case .highUV, .heatSpike:
            return AirQualitySnapshot(aqi: 85, pm25: 28.0, dominantPollutant: "O3")
        case .rainy:
            return AirQualitySnapshot(aqi: 35, pm25: 12.0, dominantPollutant: nil)
        default:
            return AirQualitySnapshot(aqi: 45, pm25: 15.0, dominantPollutant: nil)
        }
    }
}

// MARK: - Live Providers (Placeholders)

struct PlaceholderWeatherProvider: WeatherProvider {
    func fetchCurrent() async -> DailyWeatherSnapshot {
        DailyWeatherSnapshot(
            uvIndex: 0,
            temperatureCelsius: 20,
            humidityPercent: 50,
            windSpeedKmh: 10,
            condition: .unknown
        )
    }
}

struct PlaceholderUVProvider: UVProvider {
    func fetchCurrentUV() async -> Double { 0 }
}

struct PlaceholderAirQualityProvider: AirQualityProvider {
    func fetchCurrentAQI() async -> AirQualitySnapshot {
        AirQualitySnapshot(aqi: 0, pm25: nil, dominantPollutant: nil)
    }
}

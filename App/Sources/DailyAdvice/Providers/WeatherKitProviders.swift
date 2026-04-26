import Foundation
import CoreLocation

#if canImport(WeatherKit)
import WeatherKit

// MARK: - WeatherKit Weather Provider

@available(iOS 16.0, *)
struct WeatherKitWeatherProvider: WeatherProvider {
    private let service = WeatherService()
    let location: CLLocation

    func fetchCurrent() async -> DailyWeatherSnapshot {
        do {
            let current = try await service.weather(
                for: location,
                including: .current
            )
            let windSpeed = current.wind.speed.value // km/h in metric
            let condition = mapCondition(current.condition)

            return DailyWeatherSnapshot(
                uvIndex: Double(current.uvIndex.value),
                temperatureCelsius: current.temperature.value,
                humidityPercent: current.humidity * 100,
                windSpeedKmh: Double(windSpeed),
                condition: condition
            )
        } catch {
            return DailyWeatherSnapshot(
                uvIndex: 0,
                temperatureCelsius: 20,
                humidityPercent: 50,
                windSpeedKmh: 10,
                condition: .unknown
            )
        }
    }

    private func mapCondition(_ condition: WeatherKit.WeatherCondition) -> WeatherCondition {
        switch condition {
        case WeatherKit.WeatherCondition.clear, WeatherKit.WeatherCondition.mostlyClear: return .clear
        case WeatherKit.WeatherCondition.partlyCloudy, WeatherKit.WeatherCondition.mostlyCloudy: return .partlyCloudy
        case WeatherKit.WeatherCondition.cloudy, WeatherKit.WeatherCondition.foggy: return .cloudy
        case WeatherKit.WeatherCondition.rain, WeatherKit.WeatherCondition.drizzle, WeatherKit.WeatherCondition.heavyRain: return .rain
        case WeatherKit.WeatherCondition.snow, WeatherKit.WeatherCondition.sleet, WeatherKit.WeatherCondition.freezingRain, WeatherKit.WeatherCondition.heavySnow, WeatherKit.WeatherCondition.blowingSnow: return .snow
        case WeatherKit.WeatherCondition.thunderstorms, WeatherKit.WeatherCondition.isolatedThunderstorms, WeatherKit.WeatherCondition.scatteredThunderstorms, WeatherKit.WeatherCondition.strongStorms: return .thunderstorm
        case WeatherKit.WeatherCondition.haze, WeatherKit.WeatherCondition.smoky: return .fog
        default: return .unknown
        }
    }
}

// MARK: - WeatherKit UV Provider

@available(iOS 16.0, *)
struct WeatherKitUVProvider: UVProvider {
    private let service = WeatherService()
    let location: CLLocation

    func fetchCurrentUV() async -> Double {
        do {
            let current = try await service.weather(
                for: location,
                including: .current
            )
            return Double(current.uvIndex.value)
        } catch {
            return 0
        }
    }
}

#endif

// MARK: - Unified WeatherKit Environment Provider

struct WeatherKitEnvironmentProvider {
    static func createIfAvailable() async -> CompositeEnvironmentProvider? {
        #if canImport(WeatherKit)
        guard #available(iOS 16.0, *) else { return nil }
        do {
            let location = try await LocationManager.shared.fetchLocation()
            return CompositeEnvironmentProvider(
                weather: WeatherKitWeatherProvider(location: location),
                uv: WeatherKitUVProvider(location: location),
                airQuality: OpenWeatherAQProvider(location: location)
            )
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }
}

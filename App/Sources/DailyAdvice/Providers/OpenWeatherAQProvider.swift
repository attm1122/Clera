import Foundation
import CoreLocation

/// Free OpenWeatherMap Air Quality provider.
/// Falls back to placeholder if no API key is configured or the call fails.
struct OpenWeatherAQProvider: AirQualityProvider {
    let location: CLLocation

    /// Set your OpenWeatherMap API key here, or leave nil to use placeholder fallback.
    static var apiKey: String? {
        // TODO: Replace with your actual API key or load from Info.plist / environment
        nil
    }

    func fetchCurrentAQI() async -> AirQualitySnapshot {
        guard let apiKey = Self.apiKey else {
            return placeholderSnapshot
        }

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let urlString = "https://api.openweathermap.org/data/2.5/air_pollution?lat=\(lat)&lon=\(lon)&appid=\(apiKey)"

        guard let url = URL(string: urlString) else {
            return placeholderSnapshot
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(AQResponse.self, from: data)
            guard let item = response.list.first else {
                return placeholderSnapshot
            }
            return AirQualitySnapshot(
                aqi: item.main.aqi * 50, // OWM uses 1-5 scale; map to 0-250 approximate AQI
                pm25: item.components.pm2_5,
                dominantPollutant: dominantPollutant(from: item.components)
            )
        } catch {
            return placeholderSnapshot
        }
    }

    private var placeholderSnapshot: AirQualitySnapshot {
        AirQualitySnapshot(aqi: 0, pm25: nil, dominantPollutant: nil)
    }

    private func dominantPollutant(from components: AQComponents) -> String? {
        let pollutants = [
            ("PM2.5", components.pm2_5),
            ("PM10", components.pm10),
            ("O3", components.o3),
            ("NO2", components.no2),
            ("SO2", components.so2)
        ]
        return pollutants.max(by: { $0.1 < $1.1 })?.0
    }
}

// MARK: - OpenWeatherMap Response Models

private struct AQResponse: Codable {
    let list: [AQItem]
}

private struct AQItem: Codable {
    let main: AQMain
    let components: AQComponents
}

private struct AQMain: Codable {
    let aqi: Int
}

private struct AQComponents: Codable {
    let co: Double
    let no: Double
    let no2: Double
    let o3: Double
    let so2: Double
    let pm2_5: Double
    let pm10: Double
    let nh3: Double
}

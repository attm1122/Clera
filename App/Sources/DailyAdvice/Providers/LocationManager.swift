import Foundation
import CoreLocation

/// Manages location access for WeatherKit and environmental context.
@MainActor
@Observable
final class LocationManager: NSObject {
    static let shared = LocationManager()

    private let manager = CLLocationManager()

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var lastLocation: CLLocation?
    var locationError: Error?

    private var continuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    /// Fetches the current location, requesting permission if needed.
    func fetchLocation() async throws -> CLLocation {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return try await performLocationRequest()
        case .notDetermined:
            requestAuthorization()
            // Wait briefly then try again
            try await Task.sleep(nanoseconds: 500_000_000)
            authorizationStatus = manager.authorizationStatus
            if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
                return try await performLocationRequest()
            }
            throw LocationError.notAuthorized
        case .denied, .restricted:
            throw LocationError.notAuthorized
        @unknown default:
            throw LocationError.notAuthorized
        }
    }

    private func performLocationRequest() async throws -> CLLocation {
        if let last = lastLocation, last.timestamp.timeIntervalSinceNow > -300 {
            return last
        }
        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            manager.startUpdatingLocation()
        }
    }

    enum LocationError: Error {
        case notAuthorized
        case unknown
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.lastLocation = location
            self.continuation?.resume(returning: location)
            self.continuation = nil
            self.manager.stopUpdatingLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationError = error
            self.continuation?.resume(throwing: error)
            self.continuation = nil
            self.manager.stopUpdatingLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }
}

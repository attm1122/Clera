import Foundation

/// Manages user privacy consents for analytics, notifications, and data collection.
/// Persists choices via `AppPersistence` so they survive app restarts.
@MainActor
final class PrivacyConsentManager {
    static let shared = PrivacyConsentManager()

    private let persistence: AppPersistence
    private var _state: PrivacyConsentState

    var state: PrivacyConsentState { _state }

    var analyticsAllowed: Bool { _state.analytics }
    var crashReportingAllowed: Bool { _state.crashReporting }
    var marketingAllowed: Bool { _state.marketing }

    init(persistence: AppPersistence = AppPersistence()) {
        self.persistence = persistence
        if let loaded = persistence.load()?.privacySettings.consentState {
            self._state = loaded
        } else {
            self._state = PrivacyConsentState()
        }
    }

    /// Call this after onboarding to request consents.
    func requestConsents(
        analytics: Bool,
        crashReporting: Bool,
        marketing: Bool
    ) {
        _state = PrivacyConsentState(
            analytics: analytics,
            crashReporting: crashReporting,
            marketing: marketing,
            requestedAt: .now
        )
        persist()
    }

    private func persist() {
        if var appState = persistence.load() {
            appState.privacySettings.consentState = _state
            persistence.save(appState)
        }
    }
}

// MARK: - Models

struct PrivacyConsentState: Codable, Equatable, Sendable {
    var analytics: Bool = false
    var crashReporting: Bool = false
    var marketing: Bool = false
    var requestedAt: Date?
}

import Foundation

struct ReminderSettings: Codable, Equatable {
    var enabled: Bool = false
    var preferredTime: Date = Date(timeIntervalSinceReferenceDate: 31_200)
    var cadence: ReminderCadence = .daily
}

enum ReminderCadence: String, CaseIterable, Codable {
    case daily, alternateDays, weekly

    var displayName: String {
        switch self {
        case .daily: "Every Day"
        case .alternateDays: "Every Other Day"
        case .weekly: "Weekly"
        }
    }
}

struct PrivacySettings: Codable, Equatable {
    var shareAnalytics: Bool = false
    var savePhotos: Bool = true
    var consentState: PrivacyConsentState = PrivacyConsentState()
}

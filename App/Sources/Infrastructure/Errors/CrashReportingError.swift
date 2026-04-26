import Foundation

enum CrashReportingError: Error, Equatable, Sendable {
    case notConfigured
    case recordingFailed(String)
    case unknown(String)

    var developerMessage: String {
        switch self {
        case .notConfigured:
            return "Crash reporter not configured"
        case .recordingFailed(let reason):
            return "Failed to record error: \(reason)"
        case .unknown(let message):
            return message
        }
    }
}

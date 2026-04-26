import Foundation

enum CloudSyncError: Error, Equatable, Sendable {
    case notAuthenticated
    case networkFailure
    case decodingFailed
    case encodingFailed
    case conflictResolutionFailed
    case batchWriteFailed
    case documentNotFound
    case quotaExceeded
    case unknown(String)

    var userMessage: String {
        switch self {
        case .notAuthenticated:
            return "Please sign in to sync your data."
        case .networkFailure:
            return "Could not reach the cloud. Your changes are saved locally."
        case .decodingFailed, .encodingFailed:
            return "Data format issue. Please contact support."
        case .conflictResolutionFailed:
            return "Sync conflict detected. Using the latest version."
        case .batchWriteFailed:
            return "Some changes could not be saved. Retrying soon."
        case .documentNotFound:
            return "Data not found. It may have been removed."
        case .quotaExceeded:
            return "Storage limit reached. Please free up space."
        case .unknown(let message):
            return "Sync issue: \(message)"
        }
    }
}

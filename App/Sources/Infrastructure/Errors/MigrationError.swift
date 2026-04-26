import Foundation

enum MigrationError: Error, Equatable, Sendable {
    case noLocalData
    case alreadyMigrated
    case uploadFailed(String)
    case authRequired
    case partialUpload(successCount: Int, failureCount: Int)
    case unknown(String)

    var userMessage: String {
        switch self {
        case .noLocalData:
            return "No local data to migrate."
        case .alreadyMigrated:
            return "Your data is already synced."
        case .uploadFailed:
            return "Could not upload some data. Please try again."
        case .authRequired:
            return "Please sign in before migrating your data."
        case .partialUpload(let success, let failure):
            return "Uploaded \(success) items, \(failure) failed. We'll retry the rest."
        case .unknown(let message):
            return message
        }
    }
}

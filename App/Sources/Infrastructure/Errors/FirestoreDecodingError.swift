import Foundation

enum FirestoreDecodingError: Error, Equatable, Sendable {
    case missingField(String)
    case invalidType(String, expected: String, actual: String)
    case timestampDecodingFailed
    case nestedDecodingFailed(String)
    case unknown(String)

    var developerMessage: String {
        switch self {
        case .missingField(let field):
            return "Firestore document missing required field: \(field)"
        case .invalidType(let field, let expected, let actual):
            return "Firestore field '\(field)' expected \(expected) but got \(actual)"
        case .timestampDecodingFailed:
            return "Could not decode Firestore Timestamp"
        case .nestedDecodingFailed(let path):
            return "Failed to decode nested document at path: \(path)"
        case .unknown(let message):
            return message
        }
    }
}

import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

// MARK: - Firebase Configuration

/// Encapsulates Firebase setup with graceful degradation when config is missing.
enum FirebaseConfiguration {
    /// Whether Firebase is available in this build.
    /// Checks for the presence of GoogleService-Info.plist.
    static var isConfigured: Bool {
        #if canImport(FirebaseCore)
        return Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
        #else
        return false
        #endif
    }

    /// Safely configures Firebase if the plist is present.
    /// Idempotent — calling multiple times is a no-op.
    /// Logs a clear message in debug builds when missing.
    static func configure() {
        #if canImport(FirebaseCore)
        guard isConfigured else {
            #if DEBUG
            print("[Firebase] GoogleService-Info.plist not found. Firebase services are disabled.")
            print("[Firebase] Add the plist to App/Resources/ to enable cloud features.")
            #endif
            return
        }
        guard FirebaseApp.app() == nil else {
            #if DEBUG
            print("[Firebase] Firebase already configured. Skipping duplicate configuration.")
            #endif
            return
        }
        FirebaseApp.configure()
        #if DEBUG
        print("[Firebase] Firebase configured successfully.")
        #endif
        #endif
    }
}

// MARK: - Firestore Dictionary Encoding Helper

extension Encodable {
    /// Encodes this value to a Firestore-compatible dictionary.
    func asFirestoreDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let json = try JSONSerialization.jsonObject(with: data)
        guard let dict = json as? [String: Any] else {
            throw CloudSyncError.encodingFailed
        }
        return dict
    }
}

// MARK: - Firestore Timestamp Helpers

extension Date {
    /// Converts ISO8601 string back to Date for Firestore reads.
    static func fromFirestoreValue(_ value: Any) -> Date? {
        if let timestamp = value as? Date { return timestamp }
        if let string = value as? String { return ISO8601DateFormatter().date(from: string) }
        return nil
    }
}

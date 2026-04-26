import Foundation

#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

// MARK: - Crashlytics Reporter

/// Production implementation of `CrashReporting` using Firebase Crashlytics.
final class CrashlyticsReporter: CrashReporting, @unchecked Sendable {

    #if canImport(FirebaseCrashlytics)
    private let crashlytics: Crashlytics?
    #endif

    init() {
        #if canImport(FirebaseCrashlytics)
        self.crashlytics = FirebaseConfiguration.isConfigured ? Crashlytics.crashlytics() : nil
        #endif
    }

    func configure() {
        // Crashlytics is configured automatically by FirebaseApp.configure()
        #if DEBUG
        print("[Crashlytics] Reporter configured")
        #endif
    }

    func setUserId(_ userId: String?) {
        #if canImport(FirebaseCrashlytics)
        crashlytics?.setUserID(userId)
        #endif
    }

    func setCustomKey(_ key: String, value: String) {
        #if canImport(FirebaseCrashlytics)
        crashlytics?.setCustomValue(value, forKey: key)
        #endif
    }

    func recordError(_ error: Error, context: [String: String]) {
        #if canImport(FirebaseCrashlytics)
        var userInfo: [String: Any] = [:]
        for (key, value) in context {
            userInfo[key] = value
        }
        let nsError = NSError(
            domain: (error as NSError).domain,
            code: (error as NSError).code,
            userInfo: userInfo
        )
        crashlytics?.record(error: nsError)
        #endif
    }

    func log(_ message: String, level: CrashLogLevel) {
        #if canImport(FirebaseCrashlytics)
        crashlytics?.log("[\(level.rawValue.uppercased())] \(message)")
        #elseif DEBUG
        print("[Crashlytics] [\(level.rawValue.uppercased())] \(message)")
        #endif
    }
}

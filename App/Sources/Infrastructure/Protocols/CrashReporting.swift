import Foundation

/// Abstract crash and error reporter.
protocol CrashReporting: Sendable {
    func configure()
    func setUserId(_ userId: String?)
    func setCustomKey(_ key: String, value: String)
    func recordError(_ error: Error, context: [String: String])
    func log(_ message: String, level: CrashLogLevel)
}

enum CrashLogLevel: String, Sendable {
    case debug, info, warning, error
}

/// No-op reporter for previews, tests, and dev builds without Firebase.
struct NoOpCrashReporter: CrashReporting {
    func configure() {}
    func setUserId(_ userId: String?) {}
    func setCustomKey(_ key: String, value: String) {}
    func recordError(_ error: Error, context: [String: String]) {}
    func log(_ message: String, level: CrashLogLevel) {}
}

import Foundation
@testable import Clera

// MARK: - Mock Crash Reporter

final class MockCrashReporter: CrashReporting, @unchecked Sendable {
    var recordedErrors: [(Error, [String: String])] = []
    var loggedMessages: [(String, CrashLogLevel)] = []
    var customKeys: [String: String] = [:]
    var userId: String?

    func configure() {}

    func setUserId(_ userId: String?) {
        self.userId = userId
    }

    func setCustomKey(_ key: String, value: String) {
        customKeys[key] = value
    }

    func recordError(_ error: Error, context: [String: String]) {
        recordedErrors.append((error, context))
    }

    func log(_ message: String, level: CrashLogLevel) {
        loggedMessages.append((message, level))
    }
}

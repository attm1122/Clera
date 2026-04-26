import XCTest
@testable import Clera

@MainActor
final class CrashReportingTests: XCTestCase {

    func testCrashReporterReceivesNonFatalErrors() async {
        let mockAuth = MockAuthProvider()
        let mockReporter = MockCrashReporter()
        let model = AppModel(authProvider: mockAuth, crashReporter: mockReporter)

        // Trigger an action that records an error
        mockAuth.shouldSucceed = false
        mockAuth.simulatedError = .networkFailure
        await model.completeAuth(name: "Test", email: "test@example.com", password: "pw")

        try? await Task.sleep(nanoseconds: 100_000_000)

        let errors = mockReporter.recordedErrors
        XCTAssertFalse(errors.isEmpty)
    }

    func testCustomKeysAreSet() async throws {
        let mockAuth = MockAuthProvider()
        let mockReporter = MockCrashReporter()
        let model = AppModel(authProvider: mockAuth, crashReporter: mockReporter)

        // Auth state change sets custom keys
        _ = try await model.authProvider.signInAnonymously()
        try? await Task.sleep(nanoseconds: 100_000_000)

        let keys = mockReporter.customKeys
        XCTAssertNotNil(keys["auth_state"])
    }

    func testNoOpReporterDoesNothing() {
        let reporter = NoOpCrashReporter()
        reporter.configure()
        reporter.setUserId("test")
        reporter.setCustomKey("key", value: "value")
        reporter.recordError(AuthError.networkFailure, context: [:])
        reporter.log("message", level: .error)
        // No assertions needed — just verifying it doesn't crash
    }
}

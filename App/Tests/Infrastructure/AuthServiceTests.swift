import XCTest
@testable import Clera

@MainActor
final class AuthServiceTests: XCTestCase {

    func testAuthStateFlow() async throws {
        let mockAuth = MockAuthProvider()
        let model = AppModel(authProvider: mockAuth)

        XCTAssertFalse(model.hasCompletedAuth)
        XCTAssertNil(model.userProfile)

        let user = try await mockAuth.signInAnonymously()
        XCTAssertEqual(user.uid, "anon-123")

        // Allow state propagation
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(model.hasCompletedAuth)
        XCTAssertNotNil(model.userProfile)
    }

    func testSignUpSetsUserProfile() async throws {
        let mockAuth = MockAuthProvider()
        let model = AppModel(authProvider: mockAuth)

        await model.completeAuth(name: "Test User", email: "test@example.com", password: "password123")

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(model.hasCompletedAuth)
        XCTAssertEqual(model.userProfile?.name, "Test User")
        XCTAssertEqual(model.userProfile?.email, "test@example.com")
    }

    func testLogoutClearsState() async throws {
        let mockAuth = MockAuthProvider()
        let model = AppModel(authProvider: mockAuth)

        _ = try await mockAuth.signInAnonymously()
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(model.hasCompletedAuth)

        model.logout()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(model.hasCompletedAuth)
        XCTAssertNil(model.userProfile)
    }

    func testAnonymousLinking() async throws {
        let mockAuth = MockAuthProvider()
        _ = try await mockAuth.signInAnonymously()

        let linked = try await mockAuth.linkAnonymousAccount(email: "linked@example.com", password: "password123", name: "Linked User")
        XCTAssertFalse(linked.isAnonymous)
        XCTAssertEqual(linked.email, "linked@example.com")
    }

    func testAuthErrorUserMessages() {
        let errors: [AuthError] = [
            .invalidEmail,
            .weakPassword,
            .emailAlreadyInUse,
            .userNotFound,
            .networkFailure
        ]

        for error in errors {
            XCTAssertFalse(error.userMessage.isEmpty, "AuthError \(error) should have a user message")
        }
    }
}

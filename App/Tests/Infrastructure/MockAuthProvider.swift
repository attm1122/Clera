import Foundation
@testable import Clera

// MARK: - Mock Auth Provider

final class MockAuthProvider: AuthProviding, @unchecked Sendable {
    var currentUser: CleraUser?
    var authState: AsyncStream<CleraAuthState> {
        AsyncStream { continuation in
            self.stateContinuation = continuation
            continuation.yield(currentUser.map { .authenticated($0) } ?? .unauthenticated)
        }
    }

    private var stateContinuation: AsyncStream<CleraAuthState>.Continuation?
    var shouldSucceed = true
    var simulatedError: AuthError = .unknown("mock error")
    var linkAnonymousShouldSucceed = true

    func simulateState(_ state: CleraAuthState) {
        stateContinuation?.yield(state)
    }

    func signInAnonymously() async throws -> CleraUser {
        guard shouldSucceed else { throw simulatedError }
        let user = CleraUser(uid: "anon-123", email: nil, displayName: nil, isAnonymous: true)
        currentUser = user
        simulateState(.authenticated(user))
        return user
    }

    func signUp(email: String, password: String, name: String) async throws -> CleraUser {
        guard shouldSucceed else { throw simulatedError }
        let user = CleraUser(uid: "user-123", email: email, displayName: name, isAnonymous: false)
        currentUser = user
        simulateState(.authenticated(user))
        return user
    }

    func logIn(email: String, password: String) async throws -> CleraUser {
        guard shouldSucceed else { throw simulatedError }
        let user = CleraUser(uid: "user-123", email: email, displayName: nil, isAnonymous: false)
        currentUser = user
        simulateState(.authenticated(user))
        return user
    }

    func logOut() async throws {
        guard shouldSucceed else { throw simulatedError }
        currentUser = nil
        simulateState(.unauthenticated)
    }

    func sendPasswordReset(email: String) async throws {
        guard shouldSucceed else { throw simulatedError }
    }

    func linkAnonymousAccount(email: String, password: String, name: String) async throws -> CleraUser {
        guard linkAnonymousShouldSucceed else { throw simulatedError }
        let user = CleraUser(uid: "user-123", email: email, displayName: name, isAnonymous: false)
        currentUser = user
        simulateState(.authenticated(user))
        return user
    }
}

import Foundation

// MARK: - Auth Models

/// A domain representation of an authenticated user.
/// Decoupled from Firebase `User` to keep domain layer clean.
struct CleraUser: Codable, Equatable, Sendable {
    let uid: String
    let email: String?
    let displayName: String?
    let isAnonymous: Bool
}

enum CleraAuthState: Equatable, Sendable {
    case unauthenticated
    case authenticated(CleraUser)
    case loading
}

// MARK: - AuthProviding Protocol

/// Abstract authentication service.
/// The app depends on this protocol, not on Firebase directly.
protocol AuthProviding: Sendable {
    /// The currently signed-in user, if any.
    var currentUser: CleraUser? { get }

    /// A stream of auth state changes.
    var authState: AsyncStream<CleraAuthState> { get }

    /// Sign in anonymously for frictionless onboarding.
    func signInAnonymously() async throws -> CleraUser

    /// Create a new email/password account.
    func signUp(email: String, password: String, name: String) async throws -> CleraUser

    /// Sign in with an existing email/password account.
    func logIn(email: String, password: String) async throws -> CleraUser

    /// Sign out the current user.
    func logOut() async throws

    /// Send a password reset email.
    func sendPasswordReset(email: String) async throws

    /// Link the current anonymous account to an email/password credential.
    func linkAnonymousAccount(email: String, password: String, name: String) async throws -> CleraUser
}

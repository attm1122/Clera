import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

// MARK: - Firebase Auth Service

/// Production implementation of `AuthProviding` using Firebase Authentication.
/// Falls back gracefully when Firebase is not configured.
final class FirebaseAuthService: AuthProviding, @unchecked Sendable {

    private let auth: Auth?
    private var stateListener: AuthStateDidChangeListenerHandle?
    private let continuation: AsyncStream<CleraAuthState>.Continuation
    let authState: AsyncStream<CleraAuthState>

    var currentUser: CleraUser? {
        guard let user = auth?.currentUser else { return nil }
        return CleraUser(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            isAnonymous: user.isAnonymous
        )
    }

    init() {
        #if canImport(FirebaseAuth)
        self.auth = FirebaseConfiguration.isConfigured ? Auth.auth() : nil
        #else
        self.auth = nil
        #endif

        let (stream, continuation) = AsyncStream<CleraAuthState>.makeStream()
        self.authState = stream
        self.continuation = continuation

        startListening()
    }

    deinit {
        if let listener = stateListener {
            auth?.removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Auth State Listening

    private func startListening() {
        #if canImport(FirebaseAuth)
        stateListener = auth?.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                let cleraUser = CleraUser(
                    uid: user.uid,
                    email: user.email,
                    displayName: user.displayName,
                    isAnonymous: user.isAnonymous
                )
                self?.continuation.yield(.authenticated(cleraUser))
            } else {
                self?.continuation.yield(.unauthenticated)
            }
        }
        #else
        continuation.yield(.unauthenticated)
        #endif
    }

    // MARK: - Public API

    func signInAnonymously() async throws -> CleraUser {
        #if canImport(FirebaseAuth)
        guard let auth = auth else { throw AuthError.notConfigured }
        do {
            let result = try await auth.signInAnonymously()
            return CleraUser(
                uid: result.user.uid,
                email: result.user.email,
                displayName: result.user.displayName,
                isAnonymous: result.user.isAnonymous
            )
        } catch let error as NSError {
            throw mapAuthError(error)
        }
        #else
        throw AuthError.notConfigured
        #endif
    }

    func signUp(email: String, password: String, name: String) async throws -> CleraUser {
        #if canImport(FirebaseAuth)
        guard let auth = auth else { throw AuthError.notConfigured }
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            return CleraUser(
                uid: result.user.uid,
                email: result.user.email,
                displayName: name,
                isAnonymous: false
            )
        } catch let error as NSError {
            throw mapAuthError(error)
        }
        #else
        throw AuthError.notConfigured
        #endif
    }

    func logIn(email: String, password: String) async throws -> CleraUser {
        #if canImport(FirebaseAuth)
        guard let auth = auth else { throw AuthError.notConfigured }
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            return CleraUser(
                uid: result.user.uid,
                email: result.user.email,
                displayName: result.user.displayName,
                isAnonymous: false
            )
        } catch let error as NSError {
            throw mapAuthError(error)
        }
        #else
        throw AuthError.notConfigured
        #endif
    }

    func logOut() async throws {
        #if canImport(FirebaseAuth)
        guard let auth = auth else { throw AuthError.notConfigured }
        do {
            try auth.signOut()
        } catch let error as NSError {
            throw mapAuthError(error)
        }
        #else
        throw AuthError.notConfigured
        #endif
    }

    func sendPasswordReset(email: String) async throws {
        #if canImport(FirebaseAuth)
        guard let auth = auth else { throw AuthError.notConfigured }
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            throw mapAuthError(error)
        }
        #else
        throw AuthError.notConfigured
        #endif
    }

    func linkAnonymousAccount(email: String, password: String, name: String) async throws -> CleraUser {
        #if canImport(FirebaseAuth)
        guard let auth = auth else { throw AuthError.notConfigured }
        guard let currentUser = auth.currentUser, currentUser.isAnonymous else {
            throw AuthError.accountLinkingFailed
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        do {
            let result = try await currentUser.link(with: credential)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            return CleraUser(
                uid: result.user.uid,
                email: result.user.email,
                displayName: name,
                isAnonymous: false
            )
        } catch let error as NSError {
            throw mapAuthError(error)
        }
        #else
        throw AuthError.notConfigured
        #endif
    }

    // MARK: - Error Mapping

    #if canImport(FirebaseAuth)
    private func mapAuthError(_ error: NSError) -> AuthError {
        let code = AuthErrorCode(rawValue: error.code)
        switch code {
        case .invalidEmail:
            return .invalidEmail
        case .weakPassword:
            return .weakPassword
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .wrongPassword:
            return .invalidCredential
        case .userNotFound:
            return .userNotFound
        case .networkError:
            return .networkFailure
        case .credentialAlreadyInUse:
            return .accountLinkingFailed
        case .requiresRecentLogin:
            return .accountLinkingFailed
        default:
            return .unknown(error.localizedDescription)
        }
    }
    #endif
}

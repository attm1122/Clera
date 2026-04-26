import Foundation

enum AuthError: Error, Equatable, Sendable {
    case notConfigured
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case invalidCredential
    case userNotFound
    case networkFailure
    case accountLinkingFailed
    case anonymousSignInFailed
    case unknown(String)

    var userMessage: String {
        switch self {
        case .notConfigured:
            return "Authentication is not available. Please try again later."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password is too weak. Please use at least 6 characters."
        case .emailAlreadyInUse:
            return "An account with this email already exists. Try logging in."
        case .invalidCredential:
            return "Invalid email or password. Please check and try again."
        case .userNotFound:
            return "No account found with this email. Please sign up."
        case .networkFailure:
            return "Network connection issue. Please check your connection."
        case .accountLinkingFailed:
            return "Could not link account. The email may already be in use."
        case .anonymousSignInFailed:
            return "Could not start guest session. Please try again."
        case .unknown(let message):
            return message
        }
    }
}

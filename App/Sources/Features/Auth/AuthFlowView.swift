import SwiftUI

struct AuthFlowView: View {
    @Environment(AppModel.self) private var appModel
    @State private var authPath: AuthPath = .splash
    @State private var pendingName = ""
    @State private var pendingEmail = ""
    @State private var isLoading = false
    @State private var authError: AuthError?
    @State private var showError = false

    var body: some View {
        ZStack {
            CleraColor.background.ignoresSafeArea()
            switch authPath {
            case .splash:
                SplashScreenView(onComplete: { authPath = .signUp })
            case .signUp:
                SignUpView(
                    onSignUp: { name, email, password in
                        performSignUp(name: name, email: email, password: password)
                    },
                    onLogIn: { authPath = .logIn }
                )
            case .logIn:
                LogInView(
                    onLogIn: { email, password in
                        performLogIn(email: email, password: password)
                    },
                    onSignUp: { authPath = .signUp },
                    onForgotPassword: { authPath = .forgotPassword }
                )
            case .forgotPassword:
                ForgotPasswordView(
                    onSubmit: { email in
                        performPasswordReset(email: email)
                    },
                    onBack: { authPath = .logIn }
                )
            case .permissions:
                PermissionsView(onComplete: {
                    Task {
                        await appModel.completeAuth(name: pendingName, email: pendingEmail)
                    }
                })
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
                    .ignoresSafeArea()
            }
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authError?.userMessage ?? "An unknown error occurred.")
        }
    }

    // MARK: - Actions

    private func performSignUp(name: String, email: String, password: String) {
        isLoading = true
        Task {
            do {
                if let currentUser = appModel.authProvider.currentUser, currentUser.isAnonymous {
                    _ = try await appModel.authProvider.linkAnonymousAccount(email: email, password: password, name: name)
                } else {
                    _ = try await appModel.authProvider.signUp(email: email, password: password, name: name)
                }
                pendingName = name
                pendingEmail = email
                await MainActor.run {
                    isLoading = false
                    authPath = .permissions
                }
            } catch let error as AuthError {
                await MainActor.run {
                    authError = error
                    showError = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    authError = .unknown(error.localizedDescription)
                    showError = true
                    isLoading = false
                }
            }
        }
    }

    private func performLogIn(email: String, password: String) {
        isLoading = true
        Task {
            do {
                _ = try await appModel.authProvider.logIn(email: email, password: password)
                pendingName = email.components(separatedBy: "@").first ?? email
                pendingEmail = email
                await MainActor.run {
                    isLoading = false
                    authPath = .permissions
                }
            } catch let error as AuthError {
                await MainActor.run {
                    authError = error
                    showError = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    authError = .unknown(error.localizedDescription)
                    showError = true
                    isLoading = false
                }
            }
        }
    }

    private func performPasswordReset(email: String) {
        isLoading = true
        Task {
            do {
                try await appModel.authProvider.sendPasswordReset(email: email)
                await MainActor.run {
                    isLoading = false
                    authPath = .logIn
                }
            } catch let error as AuthError {
                await MainActor.run {
                    authError = error
                    showError = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    authError = .unknown(error.localizedDescription)
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

enum AuthPath {
    case splash, signUp, logIn, forgotPassword, permissions
}

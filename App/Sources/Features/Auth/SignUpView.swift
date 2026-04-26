import SwiftUI

struct SignUpView: View {
    let onSignUp: (String, String, String) -> Void
    let onLogIn: () -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                CleraSectionHeader(
                    eyebrow: CleraCopy.Auth.createAccountTitle,
                    title: CleraCopy.Auth.joinClera,
                    subtitle: CleraCopy.Auth.joinBody
                )
                .padding(.top, CleraSpacing.xl)

                CleraCard {
                    VStack(spacing: CleraSpacing.md) {
                        authField(title: CleraCopy.Auth.fullNamePlaceholder, text: $name, icon: "person")
                        authField(title: CleraCopy.Auth.emailPlaceholder, text: $email, icon: "envelope")
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                        authField(title: CleraCopy.Auth.passwordPlaceholder, text: $password, icon: "lock", isSecure: true)
                            .textContentType(.newPassword)
                    }
                }

                Button(CleraCopy.Auth.createAccountButton) {
                    onSignUp(name, email, password)
                }
                .buttonStyle(CleraPrimaryButtonStyle())
                .disabled(name.isEmpty || email.isEmpty || password.isEmpty)
                .opacity(name.isEmpty || email.isEmpty || password.isEmpty ? 0.6 : 1)

                HStack {
                    Text(CleraCopy.Auth.alreadyHaveAccount)
                        .font(.system(size: 14))
                        .foregroundStyle(CleraColor.textSecondary)
                    Button(CleraCopy.Auth.logIn) {
                        onLogIn()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CleraColor.accent)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, CleraSpacing.xl)
            }
            .padding(.horizontal, CleraSpacing.lg)
        }
        .scrollIndicators(.hidden)
        .background(CleraColor.background)
    }

    private func authField(title: String, text: Binding<String>, icon: String, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CleraColor.textSecondary)
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(CleraColor.textSecondary)
                    .frame(width: 20)
                if isSecure {
                    SecureField(title, text: text)
                        .textFieldStyle(.plain)
                } else {
                    TextField(title, text: text)
                        .textFieldStyle(.plain)
                }
            }
            .padding(CleraSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                    .fill(CleraColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CleraRadius.medium, style: .continuous)
                    .stroke(CleraColor.border, lineWidth: 1)
            )
        }
    }
}

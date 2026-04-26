import SwiftUI

struct ForgotPasswordView: View {
    let onSubmit: (String) -> Void
    let onBack: () -> Void
    @State private var email = ""
    @State private var didSubmit = false
    @State private var isValidEmail = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleraSpacing.lg) {
                CleraSectionHeader(
                    eyebrow: CleraCopy.Auth.passwordRecoveryTitle,
                    title: CleraCopy.Auth.resetPasswordTitle,
                    subtitle: CleraCopy.Auth.resetBody
                )
                .padding(.top, CleraSpacing.xl)

                CleraCard {
                    VStack(spacing: CleraSpacing.md) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(CleraCopy.Auth.emailPlaceholder)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(CleraColor.textSecondary)
                            HStack(spacing: 10) {
                                Image(systemName: "envelope")
                                    .foregroundStyle(CleraColor.textSecondary)
                                    .frame(width: 20)
                                TextField("Email", text: $email)
                                    .textFieldStyle(.plain)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .onChange(of: email) { oldValue, newValue in
                                        validateEmail(newValue)
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

                if didSubmit {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(CleraColor.success)
                        Text("\(CleraCopy.Auth.resetLinkSent) \(email)")
                            .font(.system(size: 14))
                            .foregroundStyle(CleraColor.textSecondary)
                    }
                    .padding(.vertical, CleraSpacing.sm)
                }

                Button(CleraCopy.Auth.sendResetLink) {
                    didSubmit = true
                    onSubmit(email)
                }
                .buttonStyle(CleraPrimaryButtonStyle())
                .disabled(email.isEmpty || !isValidEmail)
                .opacity(email.isEmpty || !isValidEmail ? 0.6 : 1)

                Button(CleraCopy.Auth.backToLogIn) {
                    onBack()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(CleraColor.accent)
                .frame(maxWidth: .infinity)
                .padding(.bottom, CleraSpacing.xl)
            }
            .padding(.horizontal, CleraSpacing.lg)
        }
        .scrollIndicators(.hidden)
        .background(CleraColor.background)
    }

    private func validateEmail(_ value: String) {
        let regex = #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
        isValidEmail = NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: value)
    }
}

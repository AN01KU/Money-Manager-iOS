import SwiftUI

struct LoginView: View {
    var onSkip: (() -> Void)? = nil
    var isDismissable: Bool = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.authService) private var authService
    @Environment(\.syncService) private var syncService
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDataWipeAlert = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Outer background — matches phone chrome grey
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Cancel pill — always shown at top-left
                        HStack {
                            Button("Cancel") { dismiss() }
                                .font(AppTypography.callout.weight(.medium))
                                .foregroundStyle(AppColors.primary)
                                .padding(.horizontal, AppConstants.UI.spacing20)
                                .padding(.vertical, AppConstants.UI.spacingSM)
                                .background(.white)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.10), radius: 3, y: 1)
                            Spacer()
                        }
                        .padding(.horizontal, AppConstants.UI.padding)
                        .padding(.top, AppConstants.UI.spacing12)
                        .padding(.bottom, AppConstants.UI.spacing12)

                        // Content card
                        VStack(spacing: 0) {
                            // App icon
                            ZStack {
                                Circle()
                                    .fill(AppColors.primary)
                                    .frame(width: 74, height: 74)
                                    .shadow(color: AppColors.primary.opacity(0.35), radius: 16, y: 8)
                                Text("₹")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .padding(.bottom, 22)

                            Text("Money Manager")
                                .font(AppTypography.title1)
                                .foregroundStyle(AppColors.label)
                                .padding(.bottom, 6)

                            Text("Sign in to continue")
                                .font(AppTypography.subhead)
                                .foregroundStyle(AppColors.label2)
                                .padding(.bottom, 36)

                            // Fields
                            VStack(spacing: AppConstants.UI.spacing12) {
                                LoginField(placeholder: "Email", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .textInputAutocapitalization(.never)

                                LoginField(placeholder: "Password", text: $password, isSecure: true)
                                    .textContentType(.password)
                            }
                            .padding(.bottom, AppConstants.UI.spacing20)

                            // Sign In button — dark charcoal per design spec
                            Button { login() } label: {
                                Group {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Sign In")
                                            .font(AppTypography.button)
                                            .foregroundStyle(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color("CatDark", bundle: .main))
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.radius14))
                                .shadow(color: .black.opacity(0.20), radius: 6, y: 2)
                            }
                            .disabled(isLoading)
                            .padding(.bottom, AppConstants.UI.padding)

                            #if DEBUG
                            Button("Fill Test Credentials") {
                                email = AppConfig.testEmail
                                password = AppConfig.testPassword
                            }
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.label2)
                            .padding(.bottom, 28)
                            #endif

                            // Sign up link
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundStyle(AppColors.label2)
                                Button("Sign Up") { showSignup = true }
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColors.primary)
                            }
                            .font(AppTypography.subhead)
                            .padding(.bottom, AppConstants.UI.spacing20)

                            if let onSkip {
                                Button("Continue without account") { onSkip() }
                                    .font(AppTypography.subhead)
                                    .foregroundStyle(AppColors.label2)
                                    .accessibilityIdentifier("onboarding.skip-login-button")
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, AppConstants.UI.spacing24)
                        .padding(.bottom, AppConstants.UI.spacingXL)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.radiusSheet))
                        .padding(.horizontal, AppConstants.UI.spacingXS)
                    }
                }
                .dismissKeyboardOnScroll()
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSignup, onDismiss: {
                if authService.isAuthenticated { dismiss() }
            }) {
                SignupView()
            }
            .alert("Login Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Switch Account?", isPresented: $showDataWipeAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Continue", role: .destructive) { performLogin() }
            } message: {
                Text("You were previously signed in with a different account. All local data will be cleared before signing in.")
            }
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.isValidEmail
    }

    private func login() {
        let normalizedEmail = email.lowercased()
        if let lastEmail = SessionStore.shared.getLastLoggedInEmail(), lastEmail != normalizedEmail {
            showDataWipeAlert = true
            return
        }
        performLogin()
    }

    private func performLogin() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.login(email: email, password: password)
                await syncService.fullSync()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Field component
private struct LoginField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .textFieldStyle(.plain)
        .font(AppTypography.body)
        .foregroundStyle(AppColors.label)
        .frame(height: 52)
        .padding(.horizontal, AppConstants.UI.padding)
        .background(Color(white: 0.5, opacity: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.radius14))
    }
}

#Preview {
    LoginView()
}

#Preview("Dismissable") {
    LoginView(isDismissable: true)
}

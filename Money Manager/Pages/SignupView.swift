import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.authService) private var authService
    @Environment(\.syncService) private var syncService
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var inviteCode = ""
    @State private var showingInviteCodeAlert = false
    @State private var showingVerification = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Cancel pill
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
                            // Person + badge icon
                            ZStack(alignment: .bottomTrailing) {
                                AppIcon(name: AppIcons.UI.profile, size: 56, color: AppColors.primary)

                                ZStack {
                                    Circle()
                                        .fill(AppColors.primary)
                                        .frame(width: 26, height: 26)
                                    AppIcon(name: AppIcons.UI.add, size: 13, color: .white)
                                }
                                .offset(x: 6, y: 4)
                            }
                            .padding(.bottom, 22)

                            Text("Create Account")
                                .font(AppTypography.title1)
                                .foregroundStyle(AppColors.label)
                                .padding(.bottom, 6)

                            Text("Start managing your finances today")
                                .font(AppTypography.subhead)
                                .foregroundStyle(AppColors.label2)
                                .padding(.bottom, 28)

                            // Fields
                            VStack(spacing: AppConstants.UI.spacing12) {
                                SignupField(placeholder: "Email", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .textInputAutocapitalization(.never)

                                SignupField(placeholder: "Username", text: $username)
                                    .textContentType(.username)
                                    .textInputAutocapitalization(.never)

                                SignupField(placeholder: "Password", text: $password, isSecure: true)
                                    .textContentType(.newPassword)

                                SignupField(placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
                                    .textContentType(.newPassword)

                                if !passwordsMatch && !confirmPassword.isEmpty {
                                    Text("Passwords do not match")
                                        .font(AppTypography.caption1)
                                        .foregroundStyle(AppColors.expense)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, AppConstants.UI.spacingSM)
                                }
                            }
                            .padding(.bottom, AppConstants.UI.padding)

                            #if DEBUG
                            Button("Fill Test Credentials") {
                                email = AppConfig.testEmail
                                username = AppConfig.testUsername
                                password = AppConfig.testPassword
                                confirmPassword = AppConfig.testPassword
                                inviteCode = AppConfig.testInviteCode
                            }
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.label2)
                            .padding(.bottom, AppConstants.UI.padding)
                            #endif

                            // Create Account button
                            Button {
                                if inviteCode.isEmpty {
                                    showingInviteCodeAlert = true
                                } else {
                                    signup()
                                }
                            } label: {
                                Group {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Create Account")
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
            .fullScreenCover(isPresented: $showingVerification) {
                EmailVerificationView(email: email) { dismiss() }
            }
            .alert("Signup Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Enter Invite Code", isPresented: $showingInviteCodeAlert) {
                TextField("Invite code", text: $inviteCode)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Cancel", role: .cancel) {}
                Button("Continue") { signup() }
            } message: {
                Text("This beta requires an invite code to sign up.")
            }
        }
    }

    private var isFormValid: Bool {
        email.isValidEmail && !username.isEmpty && !password.isEmpty && passwordsMatch && password.count >= 8
    }

    private var passwordsMatch: Bool {
        password == confirmPassword
    }

    private func signup() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.signup(email: email, username: username, password: password, inviteCode: inviteCode)
                await syncService.bootstrapAfterSignup()
                if authService.currentUser?.emailVerified == false {
                    showingVerification = true
                } else {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Field component
private struct SignupField: View {
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
    SignupView()
}

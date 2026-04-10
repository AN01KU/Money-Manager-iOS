//
//  LoginView.swift
//  Money Manager
//

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
            ScrollView {
                VStack(spacing: 32) {
                    LoginHeaderSection()

                    LoginFormSection(email: $email, password: $password)

                    LoginButton(isLoading: isLoading, isFormValid: isFormValid, onTap: login)

                    #if DEBUG
                    Button("Fill Test Credentials") {
                        email = "test@gmail.com"
                        password = "12345678"
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    #endif

                    LoginSignupLink(onSignUp: { showSignup = true })

                    if let onSkip {
                        Button("Continue without account") {
                            onSkip()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
            }
            .dismissKeyboardOnScroll()
            .background(Color(.systemBackground))
            .toolbar(isDismissable ? .visible : .hidden, for: .navigationBar)
            .toolbar {
                if isDismissable {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
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
                Button("Continue", role: .destructive) {
                    performLogin()
                }
            } message: {
                Text("You were previously signed in with a different account. All local data will be cleared before signing in.")
            }
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
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

private struct LoginHeaderSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "indianrupeesign.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.accent)

            Text("Money Manager")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Sign in to continue")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 40)
    }
}

private struct LoginFormSection: View {
    @Binding var email: String
    @Binding var password: String

    var body: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $email)
                .textFieldStyle(.plain)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            SecureField("Password", text: $password)
                .textFieldStyle(.plain)
                .textContentType(.password)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct LoginButton: View {
    let isLoading: Bool
    let isFormValid: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isFormValid ? AppColors.accent : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isFormValid || isLoading)
    }
}

private struct LoginSignupLink: View {
    let onSignUp: () -> Void

    var body: some View {
        HStack {
            Text("Don't have an account?")
                .foregroundStyle(.secondary)

            Button("Sign Up") {
                onSignUp()
            }
            .fontWeight(.semibold)
            .foregroundStyle(AppColors.accent)
        }
        .font(.subheadline)
    }
}

#Preview {
    LoginView()
}

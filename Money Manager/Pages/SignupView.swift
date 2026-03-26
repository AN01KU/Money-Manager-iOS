//
//  SignupView.swift
//  Money Manager
//

import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    
                    formSection
                    
                    signupButton
                }
                .padding(24)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Signup Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.plus.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.accent)
            
            Text("Create Account")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Start managing your finances today")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }
    
    private var formSection: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $email)
                .textFieldStyle(.plain)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            TextField("Username", text: $username)
                .textFieldStyle(.plain)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            SecureField("Password", text: $password)
                .textFieldStyle(.plain)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(.plain)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if !passwordsMatch && !confirmPassword.isEmpty {
                Text("Passwords do not match")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
    
    private var signupButton: some View {
        Button {
            signup()
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Create Account")
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
    
    private var isFormValid: Bool {
        !email.isEmpty && !username.isEmpty && !password.isEmpty && passwordsMatch && password.count >= 8
    }
    
    private var passwordsMatch: Bool {
        password == confirmPassword
    }
    
    private func signup() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signup(email: email, username: username, password: password)
                await syncService.bootstrapAfterSignup()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    SignupView()
}

//
//  LoginView.swift
//  Money Manager
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    
                    formSection
                    
                    loginButton
                    
                    signupLink
                }
                .padding(24)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showSignup) {
                SignupView()
            }
            .alert("Login Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private var headerSection: some View {
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
    
    private var formSection: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $email)
                .textFieldStyle(.plain)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
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
    
    private var loginButton: some View {
        Button {
            login()
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
    
    private var signupLink: some View {
        HStack {
            Text("Don't have an account?")
                .foregroundStyle(.secondary)
            
            Button("Sign Up") {
                showSignup = true
            }
            .fontWeight(.semibold)
            .foregroundStyle(AppColors.accent)
        }
        .font(.subheadline)
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func login() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.login(email: email, password: password)
                await syncService.fullSync()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    LoginView()
}

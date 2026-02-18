import SwiftUI

struct AuthView: View {
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @ObservedObject private var apiService = APIService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Image(systemName: "indianrupeesign.circle.fill")
                            .font(.system(size: 72))
                            .foregroundColor(.teal)
                        
                        Text("Money Manager")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(isLoginMode ? "Welcome back" : "Create your account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    Picker("Mode", selection: $isLoginMode) {
                        Text("Login").tag(true)
                        Text("Sign Up").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("you@example.com", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            SecureField("Password", text: $password)
                                .textContentType(isLoginMode ? .password : .newPassword)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        if !isLoginMode {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Button(action: submit) {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isLoginMode ? "Login" : "Sign Up")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid ? Color.teal : Color.teal.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: isLoginMode) {
                confirmPassword = ""
            }
        }
    }
    
    private var isFormValid: Bool {
        let emailValid = !email.trimmingCharacters(in: .whitespaces).isEmpty && email.contains("@")
        let passwordValid = password.count >= 6
        
        if isLoginMode {
            return emailValid && passwordValid
        } else {
            return emailValid && passwordValid && password == confirmPassword
        }
    }
    
    private func submit() {
        isLoading = true
        
        Task {
            if useTestData {
                try? await Task.sleep(for: .milliseconds(500))
                apiService.currentUser = TestData.currentUser
                apiService.isAuthenticated = true
            } else {
                do {
                    if isLoginMode {
                        _ = try await apiService.login(email: email.trimmingCharacters(in: .whitespaces), password: password)
                    } else {
                        _ = try await apiService.signup(email: email.trimmingCharacters(in: .whitespaces), password: password)
                    }
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            isLoading = false
        }
    }
}

#Preview("Login") {
    AuthView()
}

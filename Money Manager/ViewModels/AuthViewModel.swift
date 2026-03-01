import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoginMode = true
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var username = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    var isFormValid: Bool {
        let emailValid = !email.trimmingCharacters(in: .whitespaces).isEmpty && email.contains("@")
        let passwordValid = password.count >= 6
        let usernameValid = !username.trimmingCharacters(in: .whitespaces).isEmpty
        
        if isLoginMode {
            return emailValid && passwordValid
        } else {
            return emailValid && passwordValid && password == confirmPassword && usernameValid
        }
    }
    
    func toggleMode() {
        isLoginMode.toggle()
        confirmPassword = ""
        username = ""
    }
    
    func submit() async -> Bool {
        isLoading = true
        
        if useTestData {
            try? await Task.sleep(for: .milliseconds(500))
            APIService.shared.currentUser = TestData.currentUser
            APIService.shared.isAuthenticated = true
            isLoading = false
            return true
        } else {
            do {
                if isLoginMode {
                    _ = try await APIService.shared.login(email: email.trimmingCharacters(in: .whitespaces), password: password)
                } else {
                    _ = try await APIService.shared.signup(email: email.trimmingCharacters(in: .whitespaces), password: password, username: username.trimmingCharacters(in: .whitespaces))
                }
                
                do {
                    try await APIService.shared.syncUserData()
                } catch {
                    print("Sync failed: \(error.localizedDescription)")
                }
                
                isLoading = false
                return true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
                return false
            }
        }
    }
}

//
//  AuthService.swift
//  Money Manager
//

import Foundation

@Observable
final class AuthService {
    static let shared = AuthService()
    
    var isAuthenticated: Bool = false
    var hasCheckedAuth: Bool = false
    var currentUser: APIUser?
    var isLoading: Bool = false
    var errorMessage: String?
    
    private let keychain = KeychainHelper.shared
    private let apiClient = APIClient.shared
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSessionExpired),
            name: .authSessionExpired,
            object: nil
        )
    }
    
    @objc private func handleSessionExpired() {
        logout()
    }
    
    @MainActor
    func checkAuthState() async {
        hasCheckedAuth = false
        
        guard let _ = keychain.getToken() else {
            isAuthenticated = false
            hasCheckedAuth = true
            return
        }
        
        do {
            let user: APIUser = try await apiClient.get("/me")
            currentUser = user
            isAuthenticated = true
        } catch {
            if case APIError.unauthorized = error {
                keychain.clearAll()
                isAuthenticated = false
                currentUser = nil
            } else {
                isAuthenticated = true
            }
        }
        
        hasCheckedAuth = true
    }
    
    @MainActor
    func login(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = APILoginRequest(email: email, password: password)
            let response: APIAuthResponse = try await apiClient.post("/auth/login", body: request)
            
            keychain.saveToken(response.token)
            keychain.saveUserID(response.user.id)
            keychain.saveEmail(email)
            
            currentUser = response.user
            isAuthenticated = true
            isLoading = false
        } catch {
            isLoading = false
            if let apiError = error as? APIError {
                errorMessage = apiError.errorDescription
            } else {
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    @MainActor
    func signup(email: String, username: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = APISignupRequest(email: email, username: username, password: password)
            let response: APIAuthResponse = try await apiClient.post("/auth/signup", body: request)
            
            keychain.saveToken(response.token)
            keychain.saveUserID(response.user.id)
            keychain.saveEmail(email)
            
            currentUser = response.user
            isAuthenticated = true
            isLoading = false
        } catch {
            isLoading = false
            if let apiError = error as? APIError {
                errorMessage = apiError.errorDescription
            } else {
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    @MainActor
    func logout() {
        keychain.clearAll()
        UserDefaults.standard.removeObject(forKey: "last_sync_at")
        currentUser = nil
        isAuthenticated = false
    }
}

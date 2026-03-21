//
//  KeychainHelper.swift
//  Money Manager
//

import Foundation
import Security

final class KeychainHelper {
    static let shared = KeychainHelper()
    
    private let service = "com.moneymanager.app"
    
    private enum Keys {
        static let token = "auth_token"
        static let userID = "user_id"
        static let email = "user_email"
    }
    
    private init() {}
    
    func saveToken(_ token: String) {
        save(token, forKey: Keys.token)
    }
    
    func getToken() -> String? {
        get(forKey: Keys.token)
    }
    
    func deleteToken() {
        delete(forKey: Keys.token)
    }
    
    func saveUserID(_ userID: UUID) {
        save(userID.uuidString, forKey: Keys.userID)
    }
    
    func getUserID() -> UUID? {
        guard let uuidString = get(forKey: Keys.userID) else { return nil }
        return UUID(uuidString: uuidString)
    }
    
    func deleteUserID() {
        delete(forKey: Keys.userID)
    }
    
    func saveEmail(_ email: String) {
        save(email, forKey: Keys.email)
    }
    
    func getEmail() -> String? {
        get(forKey: Keys.email)
    }
    
    func deleteEmail() {
        delete(forKey: Keys.email)
    }
    
    func clearAll() {
        deleteToken()
        deleteUserID()
        deleteEmail()
    }
    
    private func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemAdd(attributes as CFDictionary, nil)
    }
    
    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

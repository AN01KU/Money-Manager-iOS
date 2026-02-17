//
//  KeychainService.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 15/02/26.
//

import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private let tokenKey = "com.moneymanager.authToken"
    
    private init() {}
    
    @discardableResult
    func saveToken(_ token: String) -> Bool {
        deleteToken()
        
        guard let data = token.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }
    
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    @discardableResult
    func deleteToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey
        ]
        
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
    
    var isLoggedIn: Bool {
        getToken() != nil
    }
}

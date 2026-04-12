//
//  SessionStore.swift
//  Money Manager
//

import Foundation
import Security
import OSLog

// MARK: - Token Storage

protocol TokenStorage {
    func save(_ token: String)
    func load() -> String?
    func delete()
}

final class KeychainTokenStorage: TokenStorage {
    private let service = "com.moneymanager.authtoken"
    private let account = "jwt"

    func save(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        let deleteQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        let addQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            AppLogger.auth.error("Keychain saveToken failed: OSStatus \(status)")
        }
    }

    func load() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status != errSecSuccess && status != errSecItemNotFound {
            AppLogger.auth.error("Keychain getToken failed: OSStatus \(status)")
        }
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else { return nil }
        return token
    }

    func delete() {
        let deleteQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)
    }
}

/// Manages the persisted auth session (JWT token) using the iOS Keychain.
@MainActor
final class SessionStore {
    static let shared = SessionStore()

    private let service = "com.moneymanager.authtoken"
    private let account = "jwt"

    /// Overridable token storage — defaults to Keychain, swappable in tests.
    var tokenStorage: TokenStorage = KeychainTokenStorage()

    init() {}

    // MARK: - Configure (no-op; kept for call-site compatibility)

    func configure(container: Any) {}

    // MARK: - Token

    func saveToken(_ token: String) {
        tokenStorage.save(token)
    }

    func getToken() -> String? {
        tokenStorage.load()
    }

    var isLoggedIn: Bool {
        getToken() != nil
    }

    func clearSession() {
        tokenStorage.delete()
        clearSyncSessionID()
    }

    // MARK: - Sync Session ID

    private let syncSessionIDKey = "sync_session_id"

    func saveSyncSessionID(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: syncSessionIDKey)
    }

    func getSyncSessionID() -> UUID? {
        guard let raw = UserDefaults.standard.string(forKey: syncSessionIDKey) else { return nil }
        return UUID(uuidString: raw)
    }

    private func clearSyncSessionID() {
        UserDefaults.standard.removeObject(forKey: syncSessionIDKey)
    }

    // MARK: - Last Logged In Email

    private let lastEmailKey = "last_logged_in_email"

    func saveLastLoggedInEmail(_ email: String) {
        UserDefaults.standard.set(email.lowercased(), forKey: lastEmailKey)
    }

    func getLastLoggedInEmail() -> String? {
        UserDefaults.standard.string(forKey: lastEmailKey)
    }
}

//
//  SessionStore.swift
//  Money Manager
//

import Foundation
import Security

/// Manages the persisted auth session (JWT token) using the iOS Keychain.
@MainActor
final class SessionStore {
    static let shared = SessionStore()

    private let service = "com.moneymanager.authtoken"
    private let account = "jwt"

    init() {}

    // MARK: - Configure (no-op; kept for call-site compatibility)

    func configure(container: Any) {}

    // MARK: - Token

    func saveToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }

        // Delete any existing token first
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
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func getToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else { return nil }
        return token
    }

    var isLoggedIn: Bool {
        getToken() != nil
    }

    func clearSession() {
        let deleteQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)
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

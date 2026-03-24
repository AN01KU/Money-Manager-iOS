//
//  SessionStore.swift
//  Money Manager
//

import Foundation
import SwiftData

/// Manages the persisted auth session (JWT token) using SwiftData.
/// Must be configured with a ModelContainer before use.
@MainActor
final class SessionStore {
    static let shared = SessionStore()

    private var modelContainer: ModelContainer?

    init() {}

    func configure(container: ModelContainer) {
        modelContainer = container
    }

    // MARK: - Token

    func saveToken(_ token: String) {
        guard let context = modelContainer?.mainContext else { return }
        deleteAllTokens(in: context)
        context.insert(AuthToken(token: token))
        try? context.save()
    }

    func getToken() -> String? {
        guard let context = modelContainer?.mainContext else { return nil }
        return try? context.fetch(FetchDescriptor<AuthToken>()).first?.token
    }

    var isLoggedIn: Bool {
        getToken() != nil
    }

    func clearSession() {
        guard let context = modelContainer?.mainContext else { return }
        deleteAllTokens(in: context)
        try? context.save()
    }

    // MARK: - Private

    private func deleteAllTokens(in context: ModelContext) {
        let tokens = (try? context.fetch(FetchDescriptor<AuthToken>())) ?? []
        tokens.forEach { context.delete($0) }
    }
}

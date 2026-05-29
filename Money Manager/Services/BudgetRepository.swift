import Foundation
import SwiftData

@MainActor
final class BudgetRepository {
    private let persistence: PersistenceService

    init(persistence: PersistenceService) {
        self.persistence = persistence
    }

    func currentBudget() -> UserBudget? {
        try? persistence.modelContext.fetch(FetchDescriptor<UserBudget>()).first
    }

    func setLimit(_ limit: Double) throws {
        guard limit > 0 else { throw BudgetValidationError.zeroLimit }

        let context = persistence.modelContext
        if let existing = try context.fetch(FetchDescriptor<UserBudget>()).first {
            existing.limit = limit
            existing.updatedAt = Date()
        } else {
            context.insert(UserBudget(limit: limit))
        }

        let payload = try? AppAPIClient.apiEncoder.encode(APISetBudgetRequest(limit: limit))
        try persistence.saveAndSync(
            entityType: .budget,
            entityID: UserBudget.sentinelID,
            action: .create,
            endpoint: "/me/budget",
            httpMethod: .put,
            payload: payload
        )
    }

    func clear() throws {
        let context = persistence.modelContext
        if let existing = try context.fetch(FetchDescriptor<UserBudget>()).first {
            existing.limit = nil
            existing.updatedAt = Date()
        } else {
            context.insert(UserBudget(limit: nil))
        }

        let payload = try? AppAPIClient.apiEncoder.encode(APISetBudgetRequest(limit: nil))
        try persistence.saveAndSync(
            entityType: .budget,
            entityID: UserBudget.sentinelID,
            action: .create,
            endpoint: "/me/budget",
            httpMethod: .put,
            payload: payload
        )
    }
}

// MARK: - Validation

extension BudgetRepository {
    enum BudgetValidationError: Error, LocalizedError {
        case zeroLimit

        var errorDescription: String? {
            switch self {
            case .zeroLimit: return "Budget limit must be greater than zero"
            }
        }
    }
}

// MARK: - Debug/Preview

#if DEBUG
extension BudgetRepository {
    @MainActor static let testing: BudgetRepository = BudgetRepository(persistence: .testing)
}
#endif

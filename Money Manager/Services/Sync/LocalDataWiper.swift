//
//  LocalDataWiper.swift
//  Money Manager
//

import Foundation
import SwiftData

// MARK: - WipeHandler

/// Deletes all rows of one model type from a given context.
protocol WipeHandler {
    func wipe(context: ModelContext)
}

// MARK: - Concrete handlers

struct TransactionWipeHandler: WipeHandler {
    func wipe(context: ModelContext) { try? context.delete(model: Transaction.self) }
}

struct RecurringTransactionWipeHandler: WipeHandler {
    func wipe(context: ModelContext) { try? context.delete(model: RecurringTransaction.self) }
}

struct UserBudgetWipeHandler: WipeHandler {
    func wipe(context: ModelContext) { try? context.delete(model: UserBudget.self) }
}

struct CategoryWipeHandler: WipeHandler {
    func wipe(context: ModelContext) { try? context.delete(model: Category.self) }
}

struct ChangeRecordWipeHandler: WipeHandler {
    func wipe(context: ModelContext) { try? context.delete(model: ChangeRecord.self) }
}

struct SplitGroupWipeHandler: WipeHandler {
    func wipe(context: ModelContext) { try? context.delete(model: SplitGroupModel.self) }
}

struct GroupMemberWipeHandler: WipeHandler {
    func wipe(context: ModelContext) { try? context.delete(model: GroupMemberModel.self) }
}

struct GroupTransactionWipeHandler: WipeHandler {
    func wipe(context: ModelContext) { try? context.delete(model: GroupTransactionModel.self) }
}

struct GroupBalanceWipeHandler: WipeHandler {
    func wipe(context: ModelContext) { try? context.delete(model: GroupBalanceModel.self) }
}

// MARK: - LocalDataWiper

/// Iterates a registry of `WipeHandler`s to bulk-delete local data.
///
/// `SyncService` uses two pre-built wipers: one for group data only (on logout)
/// and one for all user data (on account switch).
struct LocalDataWiper {
    private let handlers: [any WipeHandler]

    init(handlers: [any WipeHandler]) {
        self.handlers = handlers
    }

    func wipe(context: ModelContext) {
        for handler in handlers {
            handler.wipe(context: context)
        }
        try? context.save()
    }

    // MARK: - Pre-built wipers

    /// Deletes only group-related entities (used on logout).
    static let groupData = LocalDataWiper(handlers: [
        SplitGroupWipeHandler(),
        GroupMemberWipeHandler(),
        GroupTransactionWipeHandler(),
        GroupBalanceWipeHandler()
    ])

    /// Deletes all user data and group data (used on account switch).
    static let allUserData = LocalDataWiper(handlers: [
        TransactionWipeHandler(),
        RecurringTransactionWipeHandler(),
        UserBudgetWipeHandler(),
        CategoryWipeHandler(),
        ChangeRecordWipeHandler(),
        SplitGroupWipeHandler(),
        GroupMemberWipeHandler(),
        GroupTransactionWipeHandler(),
        GroupBalanceWipeHandler()
    ])
}

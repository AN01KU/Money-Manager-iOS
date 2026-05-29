import SwiftData
import Foundation

// MARK: - Schema V1 (category: String + optional categoryId)
//
// Frozen snapshot. V1Transaction/V1RecurringTransaction match the on-disk
// entity names ("Transaction", "RecurringTransaction") via originalName.
// All other models are unchanged and referenced from the main module.

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            V1Transaction.self, V1RecurringTransaction.self,
            UserBudget.self, Category.self,
            PendingChange.self, FailedChange.self, OrphanedChange.self,
            SplitGroupModel.self, GroupMemberModel.self,
            GroupTransactionModel.self, GroupBalanceModel.self
        ]
    }

    @Model
    final class V1Transaction {
        @Attribute(.unique) var id: UUID
        var type: TransactionKind
        var amount: Double
        var category: String
        var date: Date
        var time: Date?
        var transactionDescription: String?
        var notes: String?
        var createdAt: Date
        var updatedAt: Date
        @Attribute(originalName: "isDeleted") var isSoftDeleted: Bool
        var recurringExpenseId: UUID?
        var groupTransactionId: UUID?
        var groupId: UUID?
        var groupName: String?
        var settlementId: UUID?
        var categoryId: UUID?

        init() {
            id = UUID(); type = .expense; amount = 0; category = "other"
            date = Date(); createdAt = Date(); updatedAt = Date(); isSoftDeleted = false
        }
    }

    @Model
    final class V1RecurringTransaction {
        @Attribute(.unique) var id: UUID
        var name: String
        var amount: Double
        var category: String
        var frequency: RecurringFrequency
        var dayOfMonth: Int?
        var daysOfWeek: [Int]?
        var startDate: Date
        var endDate: Date?
        var isActive: Bool
        var lastAddedDate: Date?
        var notes: String?
        var categoryId: UUID?
        var type: TransactionKind
        @Attribute(originalName: "isDeleted") var isSoftDeleted: Bool
        var createdAt: Date
        var updatedAt: Date

        init() {
            id = UUID(); name = ""; amount = 0; category = "other"
            frequency = .monthly; startDate = Date(); isActive = true; type = .expense
            isSoftDeleted = false; createdAt = Date(); updatedAt = Date()
        }
    }
}

// MARK: - Schema V2 (categoryId: UUID non-optional, category removed)
//
// The current production schema. Transaction and RecurringTransaction from
// the main module are used directly.

enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            Transaction.self, RecurringTransaction.self,
            UserBudget.self, Category.self,
            PendingChange.self, FailedChange.self, OrphanedChange.self,
            SplitGroupModel.self, GroupMemberModel.self,
            GroupTransactionModel.self, GroupBalanceModel.self
        ]
    }
}

// MARK: - Schema V3 (ChangeRecord unifies PendingChange + FailedChange + OrphanedChange)
//
// The old trio of change-tracking @Model classes collapse into a single
// `ChangeRecord` with a `status: ChangeStatus` discriminator. Status-specific
// timestamps remain nullable so the audit trail is preserved through
// pending → failed → orphaned transitions.

enum SchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(3, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            Transaction.self, RecurringTransaction.self,
            UserBudget.self, Category.self,
            ChangeRecord.self,
            SplitGroupModel.self, GroupMemberModel.self,
            GroupTransactionModel.self, GroupBalanceModel.self
        ]
    }
}

// MARK: - Migration Plan

enum AppMigrationPlan: SchemaMigrationPlan {
    nonisolated(unsafe) static var schemas: [any VersionedSchema.Type] = [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    nonisolated(unsafe) static var stages: [MigrationStage] = [migrateV1toV2, migrateV2toV3]

    // Captured data passed from willMigrate to didMigrate.
    nonisolated(unsafe) private static var capturedTransactions: [(id: UUID, categoryKey: String)] = []
    nonisolated(unsafe) private static var capturedRecurrings: [(id: UUID, categoryKey: String)] = []

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            let txns = (try? context.fetch(FetchDescriptor<SchemaV1.V1Transaction>())) ?? []
            capturedTransactions = txns.map { ($0.id, $0.category) }

            let recs = (try? context.fetch(FetchDescriptor<SchemaV1.V1RecurringTransaction>())) ?? []
            capturedRecurrings = recs.map { ($0.id, $0.category) }
        },
        didMigrate: { context in
            // Build category key → UUID lookup from existing Category rows.
            let allCategories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
            var keyToUUID: [String: UUID] = Dictionary(
                uniqueKeysWithValues: allCategories.compactMap { c in
                    c.key.isEmpty ? nil : (c.key, c.id)
                }
            )

            // Seed predefined categories if none exist (offline / first launch).
            if allCategories.isEmpty {
                for predefined in PredefinedCategory.allCases {
                    let row = Category(
                        key: predefined.serverKey,
                        name: predefined.rawValue,
                        icon: predefined.icon,
                        color: predefined.paletteHex,
                        isServerPredefined: true
                    )
                    context.insert(row)
                    keyToUUID[predefined.serverKey] = row.id
                }
                try? context.save()
            }

            let otherKey = PredefinedCategory.other.serverKey
            let otherUUID: UUID
            if let existing = keyToUUID[otherKey] {
                otherUUID = existing
            } else {
                let row = Category(
                    key: otherKey,
                    name: PredefinedCategory.other.rawValue,
                    icon: PredefinedCategory.other.icon,
                    color: PredefinedCategory.other.paletteHex,
                    isServerPredefined: true
                )
                context.insert(row)
                try? context.save()
                otherUUID = row.id
            }

            // Resolve transactions.
            let txns = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
            let txnById = Dictionary(uniqueKeysWithValues: txns.map { ($0.id, $0) })
            for (id, key) in capturedTransactions {
                if let tx = txnById[id] {
                    tx.categoryId = keyToUUID[key] ?? otherUUID
                }
            }

            // Resolve recurring transactions.
            let recs = (try? context.fetch(FetchDescriptor<RecurringTransaction>())) ?? []
            let recById = Dictionary(uniqueKeysWithValues: recs.map { ($0.id, $0) })
            for (id, key) in capturedRecurrings {
                if let rec = recById[id] {
                    rec.categoryId = keyToUUID[key] ?? otherUUID
                }
            }

            try? context.save()
            capturedTransactions = []
            capturedRecurrings = []
        }
    )

    // MARK: - V2 → V3 (unify PendingChange / FailedChange / OrphanedChange into ChangeRecord)
    //
    // Custom stage: capture the trio of legacy rows in `willMigrate` and replay them
    // as `ChangeRecord` instances in `didMigrate`. We capture by value (not by managed
    // reference) because the legacy entities are removed from the schema in V3 — any
    // managed-object handles would dangle once SwiftData drops the old tables.

    private struct CapturedChange {
        let entityType: String
        let entityID: UUID
        let action: String
        let endpoint: String
        let httpMethod: String
        let payload: Data?
        let createdAt: Date
        let status: ChangeStatus
        let retryCount: Int
        let nextRetryAt: Date?
        let failedAt: Date?
        let lastError: String?
        let orphanedAt: Date?
    }

    nonisolated(unsafe) private static var capturedChanges: [CapturedChange] = []

    static let migrateV2toV3 = MigrationStage.custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self,
        willMigrate: { context in
            var rows: [CapturedChange] = []

            let pendings = (try? context.fetch(FetchDescriptor<PendingChange>())) ?? []
            for p in pendings {
                rows.append(CapturedChange(
                    entityType: p.entityType, entityID: p.entityID, action: p.action,
                    endpoint: p.endpoint, httpMethod: p.httpMethod, payload: p.payload,
                    createdAt: p.createdAt, status: .pending,
                    retryCount: p.retryCount, nextRetryAt: p.nextRetryAt,
                    failedAt: nil, lastError: nil, orphanedAt: nil
                ))
            }

            let faileds = (try? context.fetch(FetchDescriptor<FailedChange>())) ?? []
            for f in faileds {
                rows.append(CapturedChange(
                    entityType: f.entityType, entityID: f.entityID, action: f.action,
                    endpoint: f.endpoint, httpMethod: f.httpMethod, payload: f.payload,
                    createdAt: f.createdAt, status: .failed,
                    retryCount: f.retryCount, nextRetryAt: nil,
                    failedAt: f.failedAt, lastError: f.lastError, orphanedAt: nil
                ))
            }

            let orphans = (try? context.fetch(FetchDescriptor<OrphanedChange>())) ?? []
            for o in orphans {
                rows.append(CapturedChange(
                    entityType: o.entityType, entityID: o.entityID, action: o.action,
                    endpoint: o.endpoint, httpMethod: o.httpMethod, payload: o.payload,
                    createdAt: o.createdAt, status: .orphaned,
                    retryCount: 0, nextRetryAt: nil,
                    failedAt: nil, lastError: nil, orphanedAt: o.orphanedAt
                ))
            }

            capturedChanges = rows
            AppLogger.sync.info("[V2→V3] captured \(rows.count) legacy change rows (pending=\(pendings.count) failed=\(faileds.count) orphaned=\(orphans.count))")
        },
        didMigrate: { context in
            for row in capturedChanges {
                let record = ChangeRecord(
                    entityTypeRaw: row.entityType,
                    entityID: row.entityID,
                    actionRaw: row.action,
                    endpoint: row.endpoint,
                    httpMethodRaw: row.httpMethod,
                    payload: row.payload,
                    createdAt: row.createdAt,
                    status: row.status,
                    retryCount: row.retryCount,
                    nextRetryAt: row.nextRetryAt,
                    failedAt: row.failedAt,
                    lastError: row.lastError,
                    orphanedAt: row.orphanedAt
                )
                context.insert(record)
            }
            try? context.save()
            AppLogger.sync.info("[V2→V3] inserted \(capturedChanges.count) ChangeRecord rows")
            capturedChanges = []
        }
    )
}

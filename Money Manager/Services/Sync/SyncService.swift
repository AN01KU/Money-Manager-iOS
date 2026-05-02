//
//  SyncService.swift
//  Money Manager
//

import Foundation
import SwiftData

enum PreflightOutcome {
    case valid
    case invalid(reason: String)
    case skipped   // no session ID — offline queue was created before any login
}

@Observable
@MainActor
final class SyncService: SyncServiceProtocol {
    static let shared = SyncService()
    
    var isSyncing: Bool = false
    var lastSyncedAt: Date?
    var syncSuccessCount: Int = 0
    var syncFailureCount: Int = 0

    var apiClient: any APIClientProtocol = AppAPIClient.shared
    private let groupService = GroupService.shared
    private let networkMonitor = NetworkMonitor.shared
    private var authService: AuthServiceProtocol?
    private var modelContainer: ModelContainer?

    private let lastSyncKey = "last_sync_at"
    nonisolated(unsafe) private var networkObserver: Any?
    nonisolated(unsafe) private var logoutObserver: Any?

    private init() {
        lastSyncedAt = UserDefaults.standard.object(forKey: lastSyncKey) as? Date

        networkObserver = NotificationCenter.default.addObserver(
            forName: .networkDidBecomeAvailable,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.authService?.isAuthenticated == true else { return }
            Task {
                await self.syncOnReconnect()
            }
        }

        logoutObserver = NotificationCenter.default.addObserver(
            forName: .userDidLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearGroupData()
        }
    }

    deinit {
        if let observer = networkObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = logoutObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func configure(container: ModelContainer, authService: AuthServiceProtocol) {
        self.modelContainer = container
        self.authService = authService
        changeQueueManager.configure(container: container)
    }

    func clearGroupData() {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)
        try? context.delete(model: SplitGroupModel.self)
        try? context.delete(model: GroupMemberModel.self)
        try? context.delete(model: GroupTransactionModel.self)
        try? context.delete(model: GroupBalanceModel.self)
        try? context.save()
    }

    func clearAllUserData() {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)
        try? context.delete(model: Transaction.self)
        try? context.delete(model: RecurringTransaction.self)
        try? context.delete(model: MonthlyBudget.self)
        try? context.delete(model: CustomCategory.self)
        try? context.delete(model: PendingChange.self)
        try? context.delete(model: OrphanedChange.self)
        try? context.delete(model: SplitGroupModel.self)
        try? context.delete(model: GroupMemberModel.self)
        try? context.delete(model: GroupTransactionModel.self)
        try? context.delete(model: GroupBalanceModel.self)
        try? context.save()
        for key in ["last_sync_at", "selectedCurrency", "defaultBudgetLimit", "userTimezone"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    func syncOnLaunch() async {
        guard authService?.isAuthenticated == true else { return }
        guard let container = modelContainer else { return }

        AppLogger.sync.info("Sync on launch started")
        let context = ModelContext(container)

        changeQueueManager.purgeExpiredOrphans(olderThan: 7, context: context)

        let preflight = await runPreflight()
        switch preflight {
        case .valid, .skipped:
            await changeQueueManager.replayAll(context: context, isAuthenticated: true)
        case .invalid(let reason):
            AppLogger.sync.warning("Preflight failed on launch: \(reason) — orphaning queue")
            changeQueueManager.orphanAll(context: context)
            SessionStore.shared.clearSyncSessionID()
            NotificationCenter.default.post(name: .syncSessionOrphaned, object: nil)
        }

        await pullFromServer(context: context)
        AppLogger.sync.info("Sync on launch complete")
    }

    func syncOnReconnect() async {
        guard networkMonitor.isConnected else { return }
        guard let container = modelContainer else { return }

        isSyncing = true
        defer { isSyncing = false }

        AppLogger.sync.info("Sync on reconnect started")
        let context = ModelContext(container)

        let preflight = await runPreflight()
        switch preflight {
        case .valid, .skipped:
            await changeQueueManager.replayAll(context: context, isAuthenticated: authService?.isAuthenticated == true)
        case .invalid(let reason):
            AppLogger.sync.warning("Preflight failed on reconnect: \(reason) — orphaning queue")
            changeQueueManager.orphanAll(context: context)
            SessionStore.shared.clearSyncSessionID()
            NotificationCenter.default.post(name: .syncSessionOrphaned, object: nil)
        }

        await pullFromServer(context: context)
        AppLogger.sync.info("Sync on reconnect complete")
    }

    /// Calls POST /sync/preflight to verify the stored sync session is still valid.
    /// Returns `.skipped` when no session ID is stored (nothing queued offline yet).
    private func runPreflight() async -> PreflightOutcome {
        guard let sessionID = SessionStore.shared.getSyncSessionID() else {
            return .skipped
        }

        do {
            let body = APISyncPreflightRequest(syncSessionId: sessionID)
            let response: APISyncPreflightResponse = try await apiClient.post(.syncPreflight, body: body)
            return response.valid ? .valid : .invalid(reason: response.reason ?? "UNKNOWN")
        } catch let error as APIError {
            if case .syncSessionInvalid(let reason) = error {
                return .invalid(reason: reason)
            }
            // Network or server error — treat as skipped so we don't block the queue unnecessarily
            AppLogger.sync.warning("Preflight request failed: \(error) — proceeding with sync")
            return .skipped
        } catch {
            AppLogger.sync.warning("Preflight request failed: \(error) — proceeding with sync")
            return .skipped
        }
    }

    func fullSync() async {
        guard let container = modelContainer else { return }

        isSyncing = true
        defer { isSyncing = false }

        AppLogger.sync.info("Full sync started")
        let context = ModelContext(container)

        await pullFromServer(context: context)
        updateLastSyncTime()
        syncSuccessCount += 1
        AppLogger.sync.info("Full sync complete")
    }

    func bootstrapAfterSignup() async {
        guard let container = modelContainer else { return }

        isSyncing = true
        defer { isSyncing = false }

        AppLogger.sync.info("Bootstrap after signup started")
        let context = ModelContext(container)

        // 1. Pull any existing category overrides/custom categories from server
        await pullCategories(context: context)

        // 2. Enqueue all local user data as creates
        enqueueLocalData(context: context)

        // 3. Push everything to server
        await changeQueueManager.replayAll(context: context, isAuthenticated: authService?.isAuthenticated == true)

        // 4. Pull canonical state
        await pullFromServer(context: context)
        updateLastSyncTime()
        AppLogger.sync.info("Bootstrap after signup complete")
    }

    private func enqueueLocalData(context: ModelContext) {
        let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        for transaction in transactions where !transaction.isSoftDeleted {
            do {
                let payload = try AppAPIClient.apiEncoder.encode(transaction.toCreateRequest())
                changeQueueManager.enqueue(
                    entityType: "transaction",
                    entityID: transaction.id,
                    action: "create",
                    endpoint: "/transactions",
                    httpMethod: "POST",
                    payload: payload,
                    context: context
                )
            } catch {
                AppLogger.sync.error("[EnqueueLocalData] failed to encode transaction \(transaction.id): \(error) — skipping")
            }
        }

        let categories = (try? context.fetch(FetchDescriptor<CustomCategory>())) ?? []
        let customOnly = categories.filter { !$0.isPredefined }
        AppLogger.sync.debug("[EnqueueLocalData] total CustomCategory rows=\(categories.count) uploading custom-only=\(customOnly.count)")
        for category in customOnly {
            do {
                let payload = try AppAPIClient.apiEncoder.encode(category.toCreateRequest())
                changeQueueManager.enqueue(
                    entityType: "category",
                    entityID: category.id,
                    action: "create",
                    endpoint: "/categories",
                    httpMethod: "POST",
                    payload: payload,
                    context: context
                )
            } catch {
                AppLogger.sync.error("[EnqueueLocalData] failed to encode category \(category.id): \(error) — skipping")
            }
        }

        let budgets = (try? context.fetch(FetchDescriptor<MonthlyBudget>())) ?? []
        for budget in budgets {
            do {
                let payload = try AppAPIClient.apiEncoder.encode(budget.toCreateRequest())
                changeQueueManager.enqueue(
                    entityType: "budget",
                    entityID: budget.id,
                    action: "create",
                    endpoint: "/budgets",
                    httpMethod: "POST",
                    payload: payload,
                    context: context
                )
            } catch {
                AppLogger.sync.error("[EnqueueLocalData] failed to encode budget \(budget.id): \(error) — skipping")
            }
        }

        let recurringItems = (try? context.fetch(FetchDescriptor<RecurringTransaction>())) ?? []
        for item in recurringItems where !item.isSoftDeleted {
            do {
                let payload = try AppAPIClient.apiEncoder.encode(item.toCreateRequest())
                changeQueueManager.enqueue(
                    entityType: "recurring",
                    entityID: item.id,
                    action: "create",
                    endpoint: "/recurring-transactions",
                    httpMethod: "POST",
                    payload: payload,
                    context: context
                )
            } catch {
                AppLogger.sync.error("[EnqueueLocalData] failed to encode recurring \(item.id): \(error) — skipping")
            }
        }
    }
    
    private func pullFromServer(context: ModelContext) async {
        isSyncing = true
        defer { isSyncing = false }

        await pullCategories(context: context)
        await pullBudgets(context: context)
        await pullRecurring(context: context)
        await pullTransactions(context: context)

        updateLastSyncTime()
    }
    
    private func pullCategories(context: ModelContext) async {
        do {
            let response: APIListResponse<APICustomCategory> = try await apiClient.get(.syncCategories)
            upsertCategories(response.data, context: context)
        } catch {
            AppLogger.sync.error("Failed to pull categories: \(error)")
            recordSyncError()
        }
    }

    func bootstrapPredefinedCategories() async {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)
        do {
            let response: APIListResponse<APIPredefinedCategory> = try await apiClient.get(.predefinedCategories)
            upsertPredefinedCategories(response.data, context: context)
            AppLogger.sync.info("Bootstrapped \(response.data.count) predefined categories")
        } catch {
            AppLogger.sync.error("Failed to fetch predefined categories: \(error)")
        }
    }

    private func upsertPredefinedCategories(_ categories: [APIPredefinedCategory], context: ModelContext) {
        // Predefined categories are owned by the server and backed by the PredefinedCategory
        // enum as an offline fallback. We never insert them into SwiftData.
        // The only thing to do here is update any existing local override rows whose
        // server-side defaults changed (e.g. the backend renamed a predefined category).
        let localCategories = (try? context.fetch(FetchDescriptor<CustomCategory>())) ?? []
        let localOverridesByKey = Dictionary(
            uniqueKeysWithValues: localCategories.compactMap { cat -> (String, CustomCategory)? in
                guard cat.isPredefined, !cat.key.isEmpty else { return nil }
                return (cat.key, cat)
            }
        )

        for remote in categories {
            guard let local = localOverridesByKey[remote.key] else { continue }
            if let remoteUpdatedAt = remote.updatedAt, remoteUpdatedAt > local.updatedAt {
                local.name = remote.name
                local.icon = remote.icon
                local.color = remote.color
                local.isHidden = remote.isHidden ?? false
                local.updatedAt = remoteUpdatedAt
            }
        }
        try? context.save()
    }

    private func pullBudgets(context: ModelContext) async {
        do {
            let response: APIListResponse<APIMonthlyBudget> = try await apiClient.get(.syncBudgets)
            upsertBudgets(response.data, context: context)
        } catch {
            AppLogger.sync.error("Failed to pull budgets: \(error)")
            recordSyncError()
        }
    }

    private func pullRecurring(context: ModelContext) async {
        do {
            let response: APIListResponse<APIRecurringTransaction> = try await apiClient.get(.syncRecurring)
            upsertRecurring(response.data, context: context)
        } catch {
            AppLogger.sync.error("Failed to pull recurring: \(error)")
            recordSyncError()
        }
    }

    private func pullTransactions(context: ModelContext) async {
        do {
            var allTransactions: [APITransaction] = []
            var offset = 0
            let limit = 100

            while true {
                let response: APIPaginatedResponse<APITransaction> = try await apiClient.get(.syncTransactions(limit: limit, offset: offset))
                allTransactions.append(contentsOf: response.data)
                AppLogger.sync.info("pullTransactions: page offset=\(offset) returned=\(response.data.count) total=\(response.pagination.total)")

                if response.data.count < limit || offset + response.data.count >= response.pagination.total {
                    break
                }
                offset += limit
            }

            AppLogger.sync.info("pullTransactions: fetched \(allTransactions.count) transactions from server")
            upsertTransactions(allTransactions, context: context)
        } catch {
            AppLogger.sync.error("Failed to pull transactions: \(error)")
            recordSyncError()
        }
    }
    
    private func upsertTransactions(_ apiTransactions: [APITransaction], context: ModelContext) {
        let pendingDescriptor = FetchDescriptor<PendingChange>(
            predicate: #Predicate { $0.entityType == "transaction" }
        )
        let pendingChanges = (try? context.fetch(pendingDescriptor)) ?? []
        let pendingIDs = Set(pendingChanges.map { $0.entityID })
        let pendingByID = Dictionary(uniqueKeysWithValues: pendingChanges.map { ($0.entityID, $0) })

        let failedDescriptor = FetchDescriptor<FailedChange>(
            predicate: #Predicate { $0.entityType == "transaction" }
        )
        let failedIDs = Set((try? context.fetch(failedDescriptor))?.map { $0.entityID } ?? [])

        let descriptor = FetchDescriptor<Transaction>()
        let localTransactions = (try? context.fetch(descriptor)) ?? []
        let localByID = Dictionary(uniqueKeysWithValues: localTransactions.map { ($0.id, $0) })

        for remote in apiTransactions {
            guard isValid(remote) else { continue }
            if let local = localByID[remote.id] {
                if local.groupName == nil, let name = remote.groupName {
                    local.groupName = name
                }
                if local.groupId == nil, let id = remote.groupId {
                    local.groupId = id
                }
                if remote.updatedAt > local.updatedAt {
                    if let stale = pendingByID[remote.id] {
                        AppLogger.sync.warning("Conflict: server wins for transaction \(remote.id) — deleting stale pending change")
                        context.delete(stale)
                    }
                    local.applyRemote(remote)
                }
            } else {
                let tx = Transaction(
                    id: remote.id,
                    type: TransactionKind(rawValue: remote.type) ?? .expense,
                    amount: remote.amount,
                    category: remote.category,
                    date: remote.date,
                    time: remote.time,
                    transactionDescription: remote.description,
                    notes: remote.notes,
                    recurringExpenseId: remote.recurringExpenseId,
                    groupTransactionId: remote.groupTransactionId,
                    settlementId: remote.settlementId
                )
                tx.groupId = remote.groupId
                tx.groupName = remote.groupName
                context.insert(tx)
            }
        }

        // Remove local transactions that the server no longer returns and have no pending upload.
        // The server responds with is_deleted=false only, so anything missing from that set is
        // either soft-deleted on the server or an orphan (e.g. stale settlement/group transactions).
        //
        // We only purge transactions that are server-owned (settlement, group, or recurring) —
        // plain personal transactions without a pending change are left alone to avoid
        // accidentally wiping entries created offline before a first sync.
        let serverIDs = Set(apiTransactions.map { $0.id })
        for local in localTransactions {
            guard !serverIDs.contains(local.id) else { continue }      // still on server — keep
            guard !pendingIDs.contains(local.id) else { continue }     // pending upload — keep
            guard !failedIDs.contains(local.id) else { continue }      // failed upload — keep
            let isServerOwned = local.settlementId != nil
                || local.groupTransactionId != nil
                || local.recurringExpenseId != nil
            guard isServerOwned else { continue }                      // personal offline txn — keep
            AppLogger.sync.info("Purging server-owned transaction not returned by server: id=\(local.id) amount=\(local.amount) category=\(local.category) date=\(local.date) recurringId=\(local.recurringExpenseId?.uuidString ?? "nil") settlementId=\(local.settlementId?.uuidString ?? "nil") groupTxId=\(local.groupTransactionId?.uuidString ?? "nil")")
            context.delete(local)
        }

        try? context.save()
        syncCheckpoint(entityType: "transaction", serverCount: apiTransactions.count, localCount: localTransactions.count)
    }

    private func upsertRecurring(_ apiExpenses: [APIRecurringTransaction], context: ModelContext) {
        let pendingDescriptor = FetchDescriptor<PendingChange>(
            predicate: #Predicate { $0.entityType == "recurring" }
        )
        let pendingChanges = (try? context.fetch(pendingDescriptor)) ?? []
        let pendingIDs = Set(pendingChanges.map { $0.entityID })
        let pendingByID = Dictionary(uniqueKeysWithValues: pendingChanges.map { ($0.entityID, $0) })

        let failedDescriptor = FetchDescriptor<FailedChange>(
            predicate: #Predicate { $0.entityType == "recurring" }
        )
        let failedIDs = Set((try? context.fetch(failedDescriptor))?.map { $0.entityID } ?? [])

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let localRecurring = (try? context.fetch(descriptor)) ?? []
        let localByID = Dictionary(uniqueKeysWithValues: localRecurring.map { ($0.id, $0) })

        for remote in apiExpenses {
            guard isValid(remote) else { continue }
            if let local = localByID[remote.id] {
                if local.isSoftDeleted { continue }
                if remote.updatedAt > local.updatedAt {
                    if let stale = pendingByID[remote.id] {
                        AppLogger.sync.warning("Conflict: server wins for recurring \(remote.id) — deleting stale pending change")
                        context.delete(stale)
                    }
                    local.name = remote.name
                    local.amount = remote.amount
                    local.category = remote.category
                    local.frequency = RecurringFrequency(rawValue: remote.frequency) ?? local.frequency
                    local.dayOfMonth = remote.dayOfMonth
                    local.daysOfWeek = remote.daysOfWeek
                    local.startDate = remote.startDate
                    local.endDate = remote.endDate
                    local.isActive = remote.isActive
                    local.lastAddedDate = remote.lastAddedDate
                    local.notes = remote.notes
                    if let remoteType = remote.type, let kind = TransactionKind(rawValue: remoteType) {
                        local.type = kind
                    }
                    local.updatedAt = remote.updatedAt
                }
            } else {
                let item = RecurringTransaction(
                    id: remote.id,
                    name: remote.name,
                    amount: remote.amount,
                    category: remote.category,
                    frequency: RecurringFrequency(rawValue: remote.frequency) ?? .monthly,
                    dayOfMonth: remote.dayOfMonth,
                    daysOfWeek: remote.daysOfWeek,
                    startDate: remote.startDate,
                    endDate: remote.endDate,
                    isActive: remote.isActive,
                    lastAddedDate: remote.lastAddedDate,
                    notes: remote.notes,
                    type: TransactionKind(rawValue: remote.type ?? "expense") ?? .expense
                )
                context.insert(item)
            }
        }

        // Purge local recurring transactions the server no longer returns and have no pending upload.
        // Also protect entities stuck in the dead-letter queue — their create may have failed transiently.
        let serverRecurringIDs = Set(apiExpenses.map { $0.id })
        for local in localRecurring {
            guard !serverRecurringIDs.contains(local.id) else { continue }
            guard !pendingIDs.contains(local.id) else { continue }
            guard !failedIDs.contains(local.id) else { continue }
            AppLogger.sync.info("Purging recurring not on server: id=\(local.id) name=\(local.name)")
            context.delete(local)
        }

        try? context.save()
        syncCheckpoint(entityType: "recurring", serverCount: apiExpenses.count, localCount: localRecurring.count)
    }

    private func upsertBudgets(_ apiBudgets: [APIMonthlyBudget], context: ModelContext) {
        let pendingDescriptor = FetchDescriptor<PendingChange>(
            predicate: #Predicate { $0.entityType == "budget" }
        )
        let pendingChanges = (try? context.fetch(pendingDescriptor)) ?? []
        let pendingIDs = Set(pendingChanges.map { $0.entityID })
        let pendingByID = Dictionary(uniqueKeysWithValues: pendingChanges.map { ($0.entityID, $0) })

        let descriptor = FetchDescriptor<MonthlyBudget>()
        let localBudgets = (try? context.fetch(descriptor)) ?? []
        let localByID = Dictionary(uniqueKeysWithValues: localBudgets.map { ($0.id, $0) })

        for remote in apiBudgets {
            guard isValid(remote) else { continue }
            if let local = localByID[remote.id] {
                if remote.updatedAt > local.updatedAt {
                    if let stale = pendingByID[remote.id] {
                        AppLogger.sync.warning("Conflict: server wins for budget \(remote.id) — deleting stale pending change")
                        context.delete(stale)
                    }
                    local.year = remote.year
                    local.month = remote.month
                    local.limit = remote.limit
                    local.updatedAt = remote.updatedAt
                }
            } else {
                let budget = MonthlyBudget(
                    id: remote.id,
                    year: remote.year,
                    month: remote.month,
                    limit: remote.limit
                )
                context.insert(budget)
            }
        }

        // Purge local budgets the server no longer returns and have no pending upload.
        let serverBudgetIDs = Set(apiBudgets.map { $0.id })
        for local in localBudgets {
            guard !serverBudgetIDs.contains(local.id) else { continue }
            guard !pendingIDs.contains(local.id) else { continue }
            AppLogger.sync.debug("Purging budget not on server: \(local.id)")
            context.delete(local)
        }

        try? context.save()
        syncCheckpoint(entityType: "budget", serverCount: apiBudgets.count, localCount: localBudgets.count)
    }

    private func upsertCategories(_ apiCategories: [APICustomCategory], context: ModelContext) {
        let pendingDescriptor = FetchDescriptor<PendingChange>(
            predicate: #Predicate { $0.entityType == "category" }
        )
        let pendingChanges = (try? context.fetch(pendingDescriptor)) ?? []
        let pendingIDs = Set(pendingChanges.map { $0.entityID })
        let pendingByID = Dictionary(uniqueKeysWithValues: pendingChanges.map { ($0.entityID, $0) })

        let descriptor = FetchDescriptor<CustomCategory>()
        let localCategories = (try? context.fetch(descriptor)) ?? []
        let localByID = Dictionary(uniqueKeysWithValues: localCategories.map { ($0.id, $0) })
        // Predefined rows always store the canonical serverKey in `key`, so we can
        // dedupe by it without consulting the legacy camelCase `predefinedKey` field.
        let localByPredServerKey = Dictionary(
            uniqueKeysWithValues: localCategories.compactMap { cat -> (String, CustomCategory)? in
                guard cat.isPredefined, !cat.key.isEmpty else { return nil }
                return (cat.key, cat)
            }
        )

        AppLogger.sync.debug("[UpsertCategories] server returned \(apiCategories.count) categories")
        for remote in apiCategories {
            guard isValid(remote) else { continue }

            // Always store the canonical serverKey form locally, even if the server
            // returned a legacy camelCase value (e.g. "foodDining").
            let normalizedPredefinedKey = remote.predefinedKey
                .flatMap { PredefinedCategory.normalizeKey($0) }
                ?? remote.predefinedKey

            let remoteIsHidden = remote.isHidden ?? false
            let remoteIsPredefined = remote.isPredefined ?? false

            AppLogger.sync.debug("[UpsertCategories] remote id=\(remote.id) key=\(remote.key) name=\(remote.name) isPredefined=\(remoteIsPredefined) predefinedKey=\(normalizedPredefinedKey ?? "nil") isHidden=\(remoteIsHidden)")

            if let local = localByID[remote.id] {
                if remote.updatedAt > local.updatedAt {
                    if let stale = pendingByID[remote.id] {
                        AppLogger.sync.warning("Conflict: server wins for category \(remote.id) — deleting stale pending change")
                        context.delete(stale)
                    }
                    AppLogger.sync.debug("[UpsertCategories] updating by ID: \(remote.name) isHidden=\(remoteIsHidden) predefinedKey=\(normalizedPredefinedKey ?? "nil")")
                    local.key = remote.key
                    local.name = remote.name
                    local.icon = remote.icon
                    local.color = remote.color
                    local.isHidden = remoteIsHidden
                    local.isPredefined = remoteIsPredefined
                    local.predefinedKey = normalizedPredefinedKey
                    local.updatedAt = remote.updatedAt
                }
            } else if remoteIsPredefined,
                      let local = localByPredServerKey[remote.key] {
                AppLogger.sync.debug("[UpsertCategories] updating by serverKey=\(remote.key): \(remote.name) isHidden=\(remoteIsHidden)")
                if let stale = pendingByID[local.id] {
                    AppLogger.sync.warning("Conflict: server wins for category (serverKey=\(remote.key)) — deleting stale pending change")
                    context.delete(stale)
                }
                local.id = remote.id
                local.key = remote.key
                local.name = remote.name
                local.icon = remote.icon
                local.color = remote.color
                local.isHidden = remoteIsHidden
                local.isPredefined = remoteIsPredefined
                local.predefinedKey = normalizedPredefinedKey
                local.updatedAt = remote.updatedAt
            } else {
                AppLogger.sync.debug("[UpsertCategories] inserting new row: \(remote.name) isPredefined=\(remoteIsPredefined) predefinedKey=\(normalizedPredefinedKey ?? "nil") isHidden=\(remoteIsHidden)")
                let category = CustomCategory(
                    id: remote.id,
                    key: remote.key,
                    name: remote.name,
                    icon: remote.icon,
                    color: remote.color,
                    isPredefined: remoteIsPredefined,
                    predefinedKey: normalizedPredefinedKey
                )
                category.isHidden = remoteIsHidden
                category.updatedAt = remote.updatedAt
                context.insert(category)
            }
        }

        // Purge local custom categories the server no longer returns and have no pending upload.
        let serverCategoryIDs = Set(apiCategories.map { $0.id })
        for local in localCategories {
            guard !local.isPredefined else { continue }
            guard !serverCategoryIDs.contains(local.id) else { continue }
            guard !pendingIDs.contains(local.id) else { continue }
            AppLogger.sync.debug("Purging custom category not on server: \(local.id) name=\(local.name)")
            context.delete(local)
        }

        try? context.save()
        syncCheckpoint(entityType: "category", serverCount: apiCategories.count, localCount: localCategories.count)
    }
    
    private func pullGroups(context: ModelContext) async {
        do {
            let groups = try await groupService.fetchGroups()
            await upsertGroups(groups, context: context)
        } catch {
            AppLogger.sync.error("Failed to pull groups: \(error)")
        }
    }

    private func upsertGroups(_ apiGroups: [APIGroupWithDetails], context: ModelContext) async {
        // Fetch all existing local models
        let localGroups = (try? context.fetch(FetchDescriptor<SplitGroupModel>())) ?? []
        let localGroupsByID = Dictionary(uniqueKeysWithValues: localGroups.map { ($0.id, $0) })

        let localMembers = (try? context.fetch(FetchDescriptor<GroupMemberModel>())) ?? []
        let localMembersByID = Dictionary(uniqueKeysWithValues: localMembers.map { ($0.id, $0) })

        let localGroupTransactions = (try? context.fetch(FetchDescriptor<GroupTransactionModel>())) ?? []
        let localGroupTransactionsByID = Dictionary(uniqueKeysWithValues: localGroupTransactions.map { ($0.id, $0) })

        for remote in apiGroups {
            // Upsert group
            let dbGroup: SplitGroupModel
            if let existing = localGroupsByID[remote.id] {
                existing.name = remote.name
                dbGroup = existing
            } else {
                let newGroup = SplitGroupModel(
                    id: remote.id,
                    name: remote.name,
                    createdBy: remote.createdBy,
                    createdAt: remote.createdAt
                )
                context.insert(newGroup)
                dbGroup = newGroup
            }

            // Upsert members
            for member in remote.members {
                if localMembersByID[member.id] == nil {
                    let newMember = GroupMemberModel(
                        id: member.id,
                        email: member.email,
                        username: member.username,
                        joinedAt: member.joinedAt ?? Date()
                    )
                    newMember.group = dbGroup
                    context.insert(newMember)
                }
            }

            // Upsert balances — replace all for this group
            let existingBalances = (try? context.fetch(
                FetchDescriptor<GroupBalanceModel>()
            ))?.filter { $0.group?.id == remote.id } ?? []
            for b in existingBalances { context.delete(b) }

            for balance in remote.balances {
                let newBalance = GroupBalanceModel(userId: balance.userId, amount: balance.amount)
                newBalance.group = dbGroup
                context.insert(newBalance)
            }
        }

        try? context.save()

        // Sync group transactions separately (not included in list response)
        for remote in apiGroups {
            await pullGroupTransactions(groupId: remote.id, dbGroupId: remote.id, localGroupTransactionsByID: localGroupTransactionsByID, context: context)
        }
    }

    private func pullGroupTransactions(
        groupId: UUID,
        dbGroupId: UUID,
        localGroupTransactionsByID: [UUID: GroupTransactionModel],
        context: ModelContext
    ) async {
        do {
            let remote = try await groupService.fetchGroupTransactions(groupId: groupId)
            AppLogger.sync.debug("pullGroupTransactions: group=\(groupId) fetched \(remote.count) transactions")

            let localGroups = (try? context.fetch(FetchDescriptor<SplitGroupModel>())) ?? []
            guard let dbGroup = localGroups.first(where: { $0.id == dbGroupId }) else {
                AppLogger.sync.warning("pullGroupTransactions: SplitGroupModel not found for id=\(dbGroupId)")
                return
            }

            for gt in remote where !gt.isDeleted {
                if let existing = localGroupTransactionsByID[gt.id] {
                    existing.transactionDescription = gt.description ?? ""
                    existing.totalAmount = gt.totalAmount
                } else {
                    let newGT = GroupTransactionModel(
                        id: gt.id,
                        description: gt.description ?? "",
                        totalAmount: gt.totalAmount,
                        paidBy: gt.paidByUserId,
                        createdAt: gt.createdAt
                    )
                    newGT.group = dbGroup
                    context.insert(newGT)
                }
            }

            try? context.save()
        } catch {
            AppLogger.sync.error("pullGroupTransactions failed for group=\(groupId): \(error)")
        }
    }

    // MARK: - Validation

    private func isValid(_ api: APITransaction) -> Bool {
        guard !api.category.trimmingCharacters(in: .whitespaces).isEmpty else {
            AppLogger.sync.error("Validation failed: transaction \(api.id) has empty category")
            return false
        }
        return true
    }

    private func isValid(_ api: APIRecurringTransaction) -> Bool {
        guard !api.category.trimmingCharacters(in: .whitespaces).isEmpty else {
            AppLogger.sync.error("Validation failed: recurring \(api.id) has empty category")
            return false
        }
        return true
    }

    private func isValid(_ api: APIMonthlyBudget) -> Bool {
        guard api.year >= 2000 && api.year <= 2100 else {
            AppLogger.sync.error("Validation failed: budget \(api.id) has out-of-range year \(api.year)")
            return false
        }
        guard api.month >= 1 && api.month <= 12 else {
            AppLogger.sync.error("Validation failed: budget \(api.id) has out-of-range month \(api.month)")
            return false
        }
        return true
    }

    private func isValid(_ api: APICustomCategory) -> Bool {
        guard !api.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            AppLogger.sync.error("Validation failed: category \(api.id) has empty name")
            return false
        }
        return true
    }

    // MARK: - Sync Checkpoint

    private func syncCheckpoint(entityType: String, serverCount: Int, localCount: Int) {
        let delta = abs(serverCount - localCount)
        if delta > 10 && localCount > 0 {
            AppLogger.sync.warning("Sync checkpoint: \(entityType) divergence — server=\(serverCount) local=\(localCount) delta=\(delta)")
        } else {
            AppLogger.sync.debug("Sync checkpoint: \(entityType) ok — server=\(serverCount) local=\(localCount)")
        }
    }

    private func updateLastSyncTime() {
        lastSyncedAt = Date()
        UserDefaults.standard.set(lastSyncedAt, forKey: lastSyncKey)
    }

    func recordSyncError() {
        syncFailureCount += 1
    }
}

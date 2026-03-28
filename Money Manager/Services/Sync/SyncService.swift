//
//  SyncService.swift
//  Money Manager
//

import Foundation
import SwiftData

@Observable
final class SyncService: SyncServiceProtocol {
    static let shared = SyncService()
    
    var isSyncing: Bool = false
    var lastSyncedAt: Date?
    var syncSuccessCount: Int = 0
    var syncFailureCount: Int = 0

    private let apiClient = APIClient.shared
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
    
    func syncOnLaunch() async {
        guard authService?.isAuthenticated == true else { return }
        guard let container = modelContainer else { return }

        AppLogger.sync.info("Sync on launch started")
        let context = ModelContext(container)
        await changeQueueManager.replayAll(context: context, isAuthenticated: true)
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
        await changeQueueManager.replayAll(context: context, isAuthenticated: authService?.isAuthenticated == true)
        await pullFromServer(context: context)
        AppLogger.sync.info("Sync on reconnect complete")
    }

    func fullSync() async {
        guard let container = modelContainer else { return }

        isSyncing = true
        defer { isSyncing = false }

        AppLogger.sync.info("Full sync started")
        let context = ModelContext(container)
        await pullAllFromServer(context: context)
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

        // 1. Pull server-seeded categories (reconciles predefined by key)
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
        for transaction in transactions where !transaction.isDeleted {
            let payload = try? APIClient.apiEncoder.encode(transaction.toCreateRequest())
            changeQueueManager.enqueue(
                entityType: "transaction",
                entityID: transaction.id,
                action: "create",
                endpoint: "/transactions",
                httpMethod: "POST",
                payload: payload,
                context: context
            )
        }

        let categories = (try? context.fetch(FetchDescriptor<CustomCategory>())) ?? []
        for category in categories where !category.isPredefined {
            let payload = try? APIClient.apiEncoder.encode(category.toCreateRequest())
            changeQueueManager.enqueue(
                entityType: "category",
                entityID: category.id,
                action: "create",
                endpoint: "/categories",
                httpMethod: "POST",
                payload: payload,
                context: context
            )
        }

        let budgets = (try? context.fetch(FetchDescriptor<MonthlyBudget>())) ?? []
        for budget in budgets {
            let payload = try? APIClient.apiEncoder.encode(budget.toCreateRequest())
            changeQueueManager.enqueue(
                entityType: "budget",
                entityID: budget.id,
                action: "create",
                endpoint: "/budgets",
                httpMethod: "POST",
                payload: payload,
                context: context
            )
        }

        let recurringItems = (try? context.fetch(FetchDescriptor<RecurringTransaction>())) ?? []
        for item in recurringItems {
            let payload = try? APIClient.apiEncoder.encode(item.toCreateRequest())
            changeQueueManager.enqueue(
                entityType: "recurring",
                entityID: item.id,
                action: "create",
                endpoint: "/recurring-transactions",
                httpMethod: "POST",
                payload: payload,
                context: context
            )
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
    
    private func pullAllFromServer(context: ModelContext) async {
        await pullFromServer(context: context)
    }
    
    private func pullCategories(context: ModelContext) async {
        do {
            let response: APIListResponse<APICustomCategory> = try await apiClient.get("/categories")
            upsertCategories(response.data, context: context)
        } catch {
            AppLogger.sync.error("Failed to pull categories: \(error)")
            recordSyncError()
        }
    }

    private func pullBudgets(context: ModelContext) async {
        do {
            let response: APIListResponse<APIMonthlyBudget> = try await apiClient.get("/budgets")
            upsertBudgets(response.data, context: context)
        } catch {
            AppLogger.sync.error("Failed to pull budgets: \(error)")
            recordSyncError()
        }
    }

    private func pullRecurring(context: ModelContext) async {
        do {
            let response: APIListResponse<APIRecurringTransaction> = try await apiClient.get("/recurring-transactions")
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
                let queryItems = [
                    URLQueryItem(name: "limit", value: "\(limit)"),
                    URLQueryItem(name: "offset", value: "\(offset)"),
                    URLQueryItem(name: "is_deleted", value: "false")
                ]

                let response: APIPaginatedResponse<APITransaction> = try await apiClient.get("/transactions", queryItems: queryItems)
                allTransactions.append(contentsOf: response.data)

                if response.data.count < limit || offset + response.data.count >= response.pagination.total {
                    break
                }
                offset += limit
            }

            upsertTransactions(allTransactions, context: context)
        } catch {
            AppLogger.sync.error("Failed to pull transactions: \(error)")
            recordSyncError()
        }
    }
    
    private func upsertTransactions(_ apiTransactions: [APITransaction], context: ModelContext) {
        let descriptor = FetchDescriptor<Transaction>()
        let localTransactions = (try? context.fetch(descriptor)) ?? []
        let localByID = Dictionary(uniqueKeysWithValues: localTransactions.map { ($0.id, $0) })

        for remote in apiTransactions {
            if let local = localByID[remote.id] {
                if remote.updated_at > local.updatedAt {
                    local.applyRemote(remote)
                }
            } else {
                let tx = Transaction(
                    id: remote.id,
                    type: remote.type,
                    amount: Double(remote.amount) ?? 0,
                    category: remote.category,
                    date: remote.date,
                    time: remote.time,
                    transactionDescription: remote.description,
                    notes: remote.notes,
                    recurringExpenseId: remote.recurring_expense_id,
                    groupTransactionId: remote.group_transaction_id,
                    settlementId: remote.settlement_id
                )
                context.insert(tx)
            }
        }

        try? context.save()
    }
    
    private func upsertRecurring(_ apiExpenses: [APIRecurringTransaction], context: ModelContext) {
        let descriptor = FetchDescriptor<RecurringTransaction>()
        let localRecurring = (try? context.fetch(descriptor)) ?? []
        let localByID = Dictionary(uniqueKeysWithValues: localRecurring.map { ($0.id, $0) })

        for remote in apiExpenses {
            if let local = localByID[remote.id] {
                if remote.updated_at > local.updatedAt {
                    local.name = remote.name
                    local.amount = Double(remote.amount) ?? local.amount
                    local.category = remote.category
                    local.frequency = remote.frequency
                    local.dayOfMonth = remote.day_of_month
                    local.daysOfWeek = remote.days_of_week
                    local.startDate = remote.start_date
                    local.endDate = remote.end_date
                    local.isActive = remote.is_active
                    local.lastAddedDate = remote.last_added_date
                    local.notes = remote.notes
                    local.type = remote.type ?? local.type
                    local.updatedAt = remote.updated_at
                }
            } else {
                let item = RecurringTransaction(
                    id: remote.id,
                    name: remote.name,
                    amount: Double(remote.amount) ?? 0,
                    category: remote.category,
                    frequency: remote.frequency,
                    dayOfMonth: remote.day_of_month,
                    daysOfWeek: remote.days_of_week,
                    startDate: remote.start_date,
                    endDate: remote.end_date,
                    isActive: remote.is_active,
                    lastAddedDate: remote.last_added_date,
                    notes: remote.notes,
                    type: remote.type ?? "expense"
                )
                context.insert(item)
            }
        }

        try? context.save()
    }
    
    private func upsertBudgets(_ apiBudgets: [APIMonthlyBudget], context: ModelContext) {
        let descriptor = FetchDescriptor<MonthlyBudget>()
        let localBudgets = (try? context.fetch(descriptor)) ?? []
        let localByID = Dictionary(uniqueKeysWithValues: localBudgets.map { ($0.id, $0) })
        
        for remote in apiBudgets {
            if let local = localByID[remote.id] {
                if remote.updated_at > local.updatedAt {
                    local.year = remote.year
                    local.month = remote.month
                    local.limit = Double(remote.limit) ?? local.limit
                    local.updatedAt = remote.updated_at
                }
            } else {
                let budget = MonthlyBudget(
                    id: remote.id,
                    year: remote.year,
                    month: remote.month,
                    limit: Double(remote.limit) ?? 0
                )
                context.insert(budget)
            }
        }
        
        try? context.save()
    }
    
    private func upsertCategories(_ apiCategories: [APICustomCategory], context: ModelContext) {
        let descriptor = FetchDescriptor<CustomCategory>()
        let localCategories = (try? context.fetch(descriptor)) ?? []
        let localByID = Dictionary(uniqueKeysWithValues: localCategories.map { ($0.id, $0) })
        let localByPredefinedKey = Dictionary(uniqueKeysWithValues: localCategories.compactMap { cat -> (String, CustomCategory)? in
            guard let key = cat.predefinedKey else { return nil }
            return (key, cat)
        })
        
        for remote in apiCategories {
            if let local = localByID[remote.id] {
                if remote.updated_at > local.updatedAt {
                    local.name = remote.name
                    local.icon = remote.icon
                    local.color = remote.color
                    local.isHidden = remote.is_hidden
                    local.isPredefined = remote.is_predefined
                    local.predefinedKey = remote.predefined_key
                    local.updatedAt = remote.updated_at
                }
            } else if let key = remote.predefined_key,
                      let local = localByPredefinedKey[key] {
                local.id = remote.id
                local.name = remote.name
                local.icon = remote.icon
                local.color = remote.color
                local.isHidden = remote.is_hidden
                local.isPredefined = remote.is_predefined
                local.predefinedKey = remote.predefined_key
                local.updatedAt = remote.updated_at
            } else {
                let category = CustomCategory(
                    id: remote.id,
                    name: remote.name,
                    icon: remote.icon,
                    color: remote.color,
                    isPredefined: remote.is_predefined,
                    predefinedKey: remote.predefined_key
                )
                category.isHidden = remote.is_hidden
                category.updatedAt = remote.updated_at
                context.insert(category)
            }
        }
        
        try? context.save()
    }
    
    private func pullGroups(context: ModelContext) async {
        do {
            let groups = try await groupService.fetchGroups()
            upsertGroups(groups, context: context)
        } catch {
            AppLogger.sync.error("Failed to pull groups: \(error)")
        }
    }

    private func upsertGroups(_ apiGroups: [APIGroupWithDetails], context: ModelContext) {
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
                    createdBy: remote.created_by,
                    createdAt: remote.created_at
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
                        joinedAt: member.joined_at ?? Date()
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
                guard let amount = Double(balance.amount) else { continue }
                let newBalance = GroupBalanceModel(userId: balance.user_id, amount: amount)
                newBalance.group = dbGroup
                context.insert(newBalance)
            }
        }

        try? context.save()

        // Sync group transactions separately (not included in list response)
        Task {
            guard let container = modelContainer else { return }
            let transaction = ModelContext(container)
            for remote in apiGroups {
                await pullGroupTransactions(groupId: remote.id, dbGroupId: remote.id, localGroupTransactionsByID: localGroupTransactionsByID, context: transaction)
            }
        }
    }

    private func pullGroupTransactions(
        groupId: UUID,
        dbGroupId: UUID,
        localGroupTransactionsByID: [UUID: GroupTransactionModel],
        context: ModelContext
    ) async {
        // TODO(Phase 4): fetch via GET /groups/:id/transactions — group details no longer include transactions inline
        AppLogger.sync.debug("pullGroupExpenses: skipped pending Phase 4 group transaction sync refactor")
    }

    private func updateLastSyncTime() {
        lastSyncedAt = Date()
        UserDefaults.standard.set(lastSyncedAt, forKey: lastSyncKey)
    }

    func recordSyncError() {
        syncFailureCount += 1
    }
}

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
    private var modelContainer: ModelContainer?
    
    private let lastSyncKey = "last_sync_at"
    nonisolated(unsafe) private var networkObserver: Any?
    
    private init() {
        lastSyncedAt = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
        
        networkObserver = NotificationCenter.default.addObserver(
            forName: .networkDidBecomeAvailable,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, authService.isAuthenticated else { return }
            Task {
                await self.syncOnReconnect()
            }
        }
    }
    
    deinit {
        if let observer = networkObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func configure(container: ModelContainer) {
        self.modelContainer = container
        changeQueueManager.configure(container: container)
    }

    func clearGroupData() {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)
        try? context.delete(model: SplitGroupModel.self)
        try? context.delete(model: GroupMemberModel.self)
        try? context.delete(model: GroupExpenseModel.self)
        try? context.delete(model: GroupBalanceModel.self)
        try? context.save()
    }
    
    func syncOnLaunch() async {
        guard authService.isAuthenticated else { return }
        guard let container = modelContainer else { return }

        AppLogger.sync.info("Sync on launch started")
        let context = ModelContext(container)
        await changeQueueManager.replayAll(context: context)
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
        await changeQueueManager.replayAll(context: context)
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
        await changeQueueManager.replayAll(context: context)

        // 4. Pull canonical state
        await pullFromServer(context: context)
        updateLastSyncTime()
        AppLogger.sync.info("Bootstrap after signup complete")
    }

    private func enqueueLocalData(context: ModelContext) {
        let expenses = (try? context.fetch(FetchDescriptor<Expense>())) ?? []
        for expense in expenses where !expense.isDeleted {
            let payload = try? APIClient.apiEncoder.encode(expense.toCreateRequest())
            changeQueueManager.enqueue(
                entityType: "expense",
                entityID: expense.id,
                action: "create",
                endpoint: "/expenses",
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

        let recurring = (try? context.fetch(FetchDescriptor<RecurringExpense>())) ?? []
        for expense in recurring {
            let payload = try? APIClient.apiEncoder.encode(expense.toCreateRequest())
            changeQueueManager.enqueue(
                entityType: "recurring",
                entityID: expense.id,
                action: "create",
                endpoint: "/recurring-expenses",
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
        await pullRecurringExpenses(context: context)
        await pullExpenses(context: context)
        
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

    private func pullRecurringExpenses(context: ModelContext) async {
        do {
            let response: APIListResponse<APIRecurringExpense> = try await apiClient.get("/recurring-expenses")
            upsertRecurringExpenses(response.data, context: context)
        } catch {
            AppLogger.sync.error("Failed to pull recurring expenses: \(error)")
            recordSyncError()
        }
    }

    private func pullExpenses(context: ModelContext) async {
        do {
            var allExpenses: [APIExpense] = []
            var offset = 0
            let limit = 100

            while true {
                let queryItems = [
                    URLQueryItem(name: "limit", value: "\(limit)"),
                    URLQueryItem(name: "offset", value: "\(offset)"),
                    URLQueryItem(name: "is_deleted", value: "false")
                ]

                let response: APIPaginatedResponse<APIExpense> = try await apiClient.get("/expenses", queryItems: queryItems)
                allExpenses.append(contentsOf: response.data)

                if response.data.count < limit || offset + response.data.count >= response.pagination.total {
                    break
                }
                offset += limit
            }

            upsertExpenses(allExpenses, context: context)
        } catch {
            AppLogger.sync.error("Failed to pull expenses: \(error)")
            recordSyncError()
        }
    }
    
    private func upsertExpenses(_ apiExpenses: [APIExpense], context: ModelContext) {
        let descriptor = FetchDescriptor<Expense>()
        let localExpenses = (try? context.fetch(descriptor)) ?? []
        let localByID = Dictionary(uniqueKeysWithValues: localExpenses.map { ($0.id, $0) })
        
        for remote in apiExpenses {
            if let local = localByID[remote.id] {
                if remote.updated_at > local.updatedAt {
                    local.amount = Double(remote.amount) ?? local.amount
                    local.category = remote.category
                    local.date = remote.date
                    local.time = remote.time
                    local.expenseDescription = remote.description
                    local.notes = remote.notes
                    local.isDeleted = remote.is_deleted
                    local.recurringExpenseId = remote.recurring_expense_id
                    local.groupId = remote.group_id
                    local.groupName = remote.group_name
                    local.updatedAt = remote.updated_at
                }
            } else {
                let expense = Expense(
                    id: remote.id,
                    amount: Double(remote.amount) ?? 0,
                    category: remote.category,
                    date: remote.date,
                    time: remote.time,
                    expenseDescription: remote.description,
                    notes: remote.notes,
                    recurringExpenseId: remote.recurring_expense_id,
                    groupId: remote.group_id,
                    groupName: remote.group_name
                )
                context.insert(expense)
            }
        }
        
        try? context.save()
    }
    
    private func upsertRecurringExpenses(_ apiExpenses: [APIRecurringExpense], context: ModelContext) {
        let descriptor = FetchDescriptor<RecurringExpense>()
        let localExpenses = (try? context.fetch(descriptor)) ?? []
        let localByID = Dictionary(uniqueKeysWithValues: localExpenses.map { ($0.id, $0) })
        
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
                    local.updatedAt = remote.updated_at
                }
            } else {
                let expense = RecurringExpense(
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
                    notes: remote.notes
                )
                context.insert(expense)
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

        let localExpenses = (try? context.fetch(FetchDescriptor<GroupExpenseModel>())) ?? []
        let localExpensesByID = Dictionary(uniqueKeysWithValues: localExpenses.map { ($0.id, $0) })

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
                        joinedAt: member.createdAt ?? Date()
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

        // Sync group expenses separately (not included in list response)
        Task {
            guard let container = modelContainer else { return }
            let expenseContext = ModelContext(container)
            for remote in apiGroups {
                await pullGroupExpenses(groupId: remote.id, dbGroupId: remote.id, localExpensesByID: localExpensesByID, context: expenseContext)
            }
        }
    }

    private func pullGroupExpenses(
        groupId: UUID,
        dbGroupId: UUID,
        localExpensesByID: [UUID: GroupExpenseModel],
        context: ModelContext
    ) async {
        do {
            let details = try await groupService.fetchGroupDetails(groupId: groupId)
            let groups = (try? context.fetch(FetchDescriptor<SplitGroupModel>())) ?? []
            guard let dbGroup = groups.first(where: { $0.id == dbGroupId }) else { return }

            for expense in details.group.expenses {
                if localExpensesByID[expense.id] == nil {
                    let newExpense = GroupExpenseModel(
                        id: expense.id,
                        description: expense.description,
                        totalAmount: Double(expense.amount) ?? 0,
                        paidBy: expense.user_id,
                        createdAt: expense.created_at
                    )
                    newExpense.group = dbGroup
                    context.insert(newExpense)
                }
            }
            try? context.save()
        } catch {
            AppLogger.sync.error("Failed to pull expenses for group \(groupId): \(error)")
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

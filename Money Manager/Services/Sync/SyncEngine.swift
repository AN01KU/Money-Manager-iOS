//
//  SyncEngine.swift
//  Money Manager
//

import Foundation
import SwiftData

@Observable
final class SyncEngine {
    static let shared = SyncEngine()
    
    var isSyncing: Bool = false
    var lastSyncedAt: Date?
    
    private let apiClient = APIClient.shared
    private let changeQueueManager = ChangeQueueManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private var modelContainer: ModelContainer?
    
    private let lastSyncKey = "last_sync_at"
    
    private init() {
        lastSyncedAt = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNetworkAvailable),
            name: .networkDidBecomeAvailable,
            object: nil
        )
    }
    
    func configure(container: ModelContainer) {
        self.modelContainer = container
        changeQueueManager.configure(container: container)
    }
    
    @objc private func handleNetworkAvailable() {
        guard AuthService.shared.isAuthenticated else { return }
        Task {
            await syncOnReconnect()
        }
    }
    
    func syncOnLaunch() async {
        guard AuthService.shared.isAuthenticated else { return }
        guard let container = modelContainer else { return }
        
        let context = ModelContext(container)
        await changeQueueManager.replayAll(context: context)
        await pullFromServer(context: context)
    }
    
    func syncOnReconnect() async {
        guard networkMonitor.isConnected else { return }
        guard let container = modelContainer else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let context = ModelContext(container)
        await changeQueueManager.replayAll(context: context)
        await pullFromServer(context: context)
    }
    
    func fullSync() async {
        guard let container = modelContainer else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let context = ModelContext(container)
        await pullAllFromServer(context: context)
        updateLastSyncTime()
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
            let response: [APICustomCategory] = try await apiClient.get("/categories")
            upsertCategories(response, context: context)
        } catch {
            print("Failed to pull categories: \(error)")
        }
    }
    
    private func pullBudgets(context: ModelContext) async {
        do {
            let response: APIListResponse<APIMonthlyBudget> = try await apiClient.get("/budgets")
            upsertBudgets(response.data, context: context)
        } catch {
            print("Failed to pull budgets: \(error)")
        }
    }
    
    private func pullRecurringExpenses(context: ModelContext) async {
        do {
            let response: [APIRecurringExpense] = try await apiClient.get("/recurring-expenses")
            upsertRecurringExpenses(response, context: context)
        } catch {
            print("Failed to pull recurring expenses: \(error)")
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
            print("Failed to pull expenses: \(error)")
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
    
    private func updateLastSyncTime() {
        lastSyncedAt = Date()
        UserDefaults.standard.set(lastSyncedAt, forKey: lastSyncKey)
    }
}

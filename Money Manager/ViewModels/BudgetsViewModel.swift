import SwiftUI
import SwiftData

@MainActor
@Observable class BudgetsViewModel {
    var showBudgetSheet = false
    var referenceDate: Date = Date()

    var allTransactions: [Transaction] = []
    /// The single per-user budget row fetched from SwiftData.
    var userBudget: UserBudget?
    var modelContext: ModelContext?

    var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        guard
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)),
            let firstDayNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)
        else { return [] }

        return allTransactions.filter { transaction in
            !transaction.isSoftDeleted &&
            transaction.type == .expense &&
            transaction.date >= startOfMonth &&
            transaction.date < firstDayNextMonth
        }
    }

    var budgetLimit: Double? { userBudget?.limit }

    var totalSpent: Double {
        currentMonthTransactions.reduce(0) { $0 + $1.amount }
    }

    var remainingBudget: Double {
        guard let limit = budgetLimit else { return 0 }
        return max(0, limit - totalSpent)
    }

    var budgetPercentage: Int {
        guard let limit = budgetLimit, limit > 0 else { return 0 }
        return Int((totalSpent / limit) * 100.0)
    }

    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = referenceDate
        guard
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)),
            let firstDayNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)
        else { return 0 }

        let startOfToday = calendar.startOfDay(for: today)
        let daysLeft = calendar.dateComponents([.day], from: startOfToday, to: firstDayNextMonth).day ?? 0
        return max(0, daysLeft)
    }

    var dailyAverage: Double {
        guard daysRemaining > 0 else { return 0 }
        return remainingBudget / Double(daysRemaining + 1)
    }

    private var daysElapsed: Int {
        let calendar = Calendar.current
        let today = referenceDate
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)) else { return 1 }
        return max(1, (calendar.dateComponents([.day], from: startOfMonth, to: today).day ?? 0) + 1)
    }

    var projectedMonthEnd: Double {
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: referenceDate)?.count ?? 30
        let dailyRate = totalSpent / Double(daysElapsed)
        let daysLeft = daysInMonth - daysElapsed
        return totalSpent + (dailyRate * Double(daysLeft))
    }

    var insightIcon: String {
        guard let limit = budgetLimit, limit > 0 else { return "checkmark.circle.fill" }
        if totalSpent >= limit { return "exclamationmark.triangle.fill" }
        if projectedMonthEnd > limit { return "arrow.up.circle.fill" }
        return "checkmark.circle.fill"
    }

    var insightColor: Color {
        guard let limit = budgetLimit, limit > 0 else { return AppColors.positive }
        if totalSpent >= limit { return AppColors.expense }
        if projectedMonthEnd > limit { return AppColors.budgetCaution }
        return AppColors.positive
    }

    var spendingInsight: String? {
        guard let limit = budgetLimit, limit > 0 else { return nil }
        guard daysElapsed > 1 else { return nil }

        let projected = projectedMonthEnd
        let overspend = projected - limit

        if totalSpent >= limit {
            return "You've exceeded your budget"
        } else if overspend > 0 {
            return "At this rate you'll overspend by \(CurrencyFormatter.format(overspend))"
        } else {
            return "On track — projected \(CurrencyFormatter.format(projected)) of \(CurrencyFormatter.format(limit))"
        }
    }

    func configure(allTransactions: [Transaction], userBudget: UserBudget?, modelContext: ModelContext?) {
        self.allTransactions = allTransactions
        self.userBudget = userBudget
        self.modelContext = modelContext
    }

    // MARK: - Mutations

    enum BudgetValidationError: Error, LocalizedError {
        case zeroLimit

        var errorDescription: String? {
            switch self {
            case .zeroLimit: return "Budget limit must be greater than zero"
            }
        }
    }

    /// Sets the per-user budget to `limit`. Enqueues a PUT /me/budget sync change.
    func saveBudget(
        limit: Double,
        context: ModelContext,
        changeQueue: ChangeQueueManagerProtocol = changeQueueManager
    ) throws {
        guard limit > 0 else { throw BudgetValidationError.zeroLimit }

        let budget: UserBudget
        let existing = try context.fetch(FetchDescriptor<UserBudget>()).first
        if let existing {
            existing.limit = limit
            existing.updatedAt = Date()
            budget = existing
        } else {
            let newBudget = UserBudget(limit: limit)
            context.insert(newBudget)
            budget = newBudget
        }
        try context.save()

        let payload = try? AppAPIClient.apiEncoder.encode(APISetBudgetRequest(limit: limit))
        changeQueue.enqueue(
            entityType: .budget,
            entityID: budget.id,
            action: .create,
            endpoint: "/me/budget",
            httpMethod: .put,
            payload: payload,
            context: context
        )
    }

    /// Clears the per-user budget by sending {"limit": null} to PUT /me/budget.
    func clearBudget(
        context: ModelContext,
        changeQueue: ChangeQueueManagerProtocol = changeQueueManager
    ) throws {
        let existing = try context.fetch(FetchDescriptor<UserBudget>()).first
        if let existing {
            existing.limit = nil
            existing.updatedAt = Date()
        } else {
            context.insert(UserBudget(limit: nil))
        }
        try context.save()

        let payload = try? AppAPIClient.apiEncoder.encode(APISetBudgetRequest(limit: nil))
        changeQueue.enqueue(
            entityType: .budget,
            entityID: UserBudget.sentinelID,
            action: .create,
            endpoint: "/me/budget",
            httpMethod: .put,
            payload: payload,
            context: context
        )
    }
}

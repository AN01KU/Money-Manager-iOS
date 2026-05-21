import Foundation

struct Spending {
    let income: Decimal
    let expense: Decimal
    /// Expense totals grouped by category name.
    let byCategory: [String: Decimal]
    /// Transactions matching the date interval and optional search term, excluding soft-deleted rows.
    let filtered: [Transaction]

    @MainActor static func from(
        transactions: [Transaction],
        in interval: DateInterval,
        search: String? = nil
    ) -> Spending {
        let active = transactions.filter {
            !$0.isSoftDeleted &&
            $0.date >= interval.start &&
            $0.date <= interval.end
        }

        let matched: [Transaction]
        if let search, !search.isEmpty {
            matched = active.filter {
                $0.category.localizedStandardContains(search) ||
                ($0.transactionDescription?.localizedStandardContains(search) ?? false) ||
                ($0.notes?.localizedStandardContains(search) ?? false)
            }
        } else {
            matched = active
        }

        var income: Decimal = 0
        var expense: Decimal = 0
        var byCategory: [String: Decimal] = [:]

        for t in active {
            let amount = Decimal(t.amount)
            if t.type == .income {
                income += amount
            } else {
                expense += amount
                byCategory[t.category, default: 0] += amount
            }
        }

        return Spending(income: income, expense: expense, byCategory: byCategory, filtered: matched)
    }
}

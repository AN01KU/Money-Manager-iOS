import SwiftUI

/// Classifies budget health into three tiers based on percentage of limit spent.
enum BudgetStatus: Equatable {
    case safe
    case caution
    case danger

    init(spent: Double, limit: Double) {
        guard limit > 0 else { self = .safe; return }
        self.init(percentage: Int((spent / limit) * 100))
    }

    init(percentage: Int) {
        if percentage >= 100 {
            self = .danger
        } else if percentage >= 80 {
            self = .caution
        } else {
            self = .safe
        }
    }

    var color: Color {
        switch self {
        case .safe:    return AppColors.budgetSafe
        case .caution: return AppColors.budgetCaution
        case .danger:  return AppColors.budgetDanger
        }
    }

    var icon: String {
        switch self {
        case .safe:    return "checkmark.circle.fill"
        case .caution: return "exclamationmark.circle.fill"
        case .danger:  return "exclamationmark.triangle.fill"
        }
    }

    var title: String {
        switch self {
        case .safe:    return "Within Budget"
        case .caution: return "Approaching Limit"
        case .danger:  return "Over Budget"
        }
    }

    func message(spent: Double, limit: Double) -> String {
        switch self {
        case .danger:
            return "You've exceeded by \(CurrencyFormatter.format(spent - limit))"
        case .caution, .safe:
            return "\(CurrencyFormatter.format(limit - spent)) remaining\(self == .safe ? " this month" : "")"
        }
    }
}

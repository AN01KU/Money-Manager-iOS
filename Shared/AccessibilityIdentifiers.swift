import Foundation

/// Namespace for all accessibility identifiers used in UI tests.
///
/// Use these constants in both the app source and UI test files to avoid
/// fragile string literals and to get compile-time safety when identifiers change.
public enum A11y {
    public enum Onboarding {
        public static let getStartedButton = "onboarding.get-started-button"
        public static let skipButton = "onboarding.skip-button"
        public static let skipLoginButton = "onboarding.skip-login-button"
    }

    public enum Overview {
        public static let dateFilterButton = "overview.date-filter-button"
        public static let budgetCard = "overview.budget-card"
        public static let noBudgetCard = "overview.no-budget-card"
        public static let emptyState = "overview.empty-state"
    }

    public enum Budget {
        public static let monthSelector = "budget.month-selector"
        public static let card = "budget.card"
        public static let editButton = "budget.edit-button"
        public static let noBudgetCard = "budget.no-budget-card"
        public static let amountField = "budget.amount-field"
        public static let cancelButton = "budget.cancel-button"
        public static let saveButton = "budget.save-button"
    }

    public enum Transaction {
        public static let row = "transaction.row"
        public static let addButton = "transactions.add-button"
        public static let fab = "fab-add"
        public static let amountField = "amount-field"
        public static let descriptionField = "description-field"
        public static let categoryPickerButton = "category-picker-button"
        public static let cancelButton = "cancel-button"
        public static let saveButton = "save-button"
    }

    public enum TransactionDetail {
        public static let amount = "transaction-detail.amount"
        public static let editButton = "transaction-detail.edit-button"
        public static let deleteButton = "transaction-detail.delete-button"
    }

    public enum Recurring {
        public static let addButton = "recurring.add-button"
        public static let row = "recurring.row"
        public static let nameField = "recurring.name-field"
        public static let amountField = "recurring.amount-field"
        public static let cancelButton = "recurring.cancel-button"
        public static let saveButton = "recurring.save-button"
    }

    public enum Settings {
        public static let budgetsRow = "settings.budgets-row"
        public static let categoriesRow = "settings.categories-row"
        public static let recurringRow = "settings.recurring-row"
    }

    public enum Groups {
        public static let groupRow = "groups.group-row"
    }
}

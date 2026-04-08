import SwiftData
@testable import Money_Manager

/// Returns an in-memory ModelContainer with the full app schema.
/// Use this in every test that needs a ModelContext — do NOT construct
/// partial schemas, as SwiftData requires all related models to be
/// registered together or the container will fail to load.
func makeTestContainer() throws -> ModelContainer {
    let schema = Schema([
        Transaction.self, RecurringTransaction.self, MonthlyBudget.self, CustomCategory.self,
        PendingChange.self, FailedChange.self, AuthToken.self,
        SplitGroupModel.self, GroupMemberModel.self, GroupTransactionModel.self, GroupBalanceModel.self
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: config)
}

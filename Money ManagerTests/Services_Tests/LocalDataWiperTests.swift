import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct LocalDataWiperTests {

    private func makeContext() throws -> ModelContext {
        ModelContext(try makeTestContainer())
    }

    // MARK: - groupData wiper

    @Test func testGroupDataWiper_deletesGroupEntities() throws {
        let context = try makeContext()
        context.insert(SplitGroupModel(id: UUID(), name: "G1", createdBy: UUID(), createdAt: Date()))
        context.insert(GroupMemberModel(id: UUID(), email: "a@b.com", username: "u", joinedAt: Date()))
        context.insert(GroupTransactionModel(id: UUID(), description: "dinner", totalAmount: 30, paidBy: UUID(), createdAt: Date()))
        context.insert(GroupBalanceModel(id: UUID(), userId: UUID(), amount: 10))
        try? context.save()

        LocalDataWiper.groupData.wipe(context: context)

        #expect((try? context.fetch(FetchDescriptor<SplitGroupModel>()))?.isEmpty == true)
        #expect((try? context.fetch(FetchDescriptor<GroupMemberModel>()))?.isEmpty == true)
        #expect((try? context.fetch(FetchDescriptor<GroupTransactionModel>()))?.isEmpty == true)
        #expect((try? context.fetch(FetchDescriptor<GroupBalanceModel>()))?.isEmpty == true)
    }

    @Test func testGroupDataWiper_preservesPersonalEntities() throws {
        let context = try makeContext()
        context.insert(Transaction(amount: 10, categoryId: UUID(), date: Date()))
        context.insert(RecurringTransaction(name: "Netflix", amount: 10, categoryId: UUID(), frequency: .monthly))
        try? context.save()

        LocalDataWiper.groupData.wipe(context: context)

        #expect((try? context.fetch(FetchDescriptor<Transaction>()))?.count == 1)
        #expect((try? context.fetch(FetchDescriptor<RecurringTransaction>()))?.count == 1)
    }

    // MARK: - allUserData wiper

    @Test func testAllUserDataWiper_deletesAllRegisteredEntities() throws {
        let context = try makeContext()
        context.insert(Transaction(amount: 10, categoryId: UUID(), date: Date()))
        context.insert(RecurringTransaction(name: "Netflix", amount: 10, categoryId: UUID(), frequency: .monthly))
        context.insert(UserBudget(limit: 1000))
        context.insert(Money_Manager.Category(name: "Food", icon: "fork.knife", color: "#FF0000"))
        context.insert(ChangeRecord.makePending(entityType: "transaction", entityID: UUID(), action: "create", endpoint: "/transactions", httpMethod: "POST", payload: nil))
        context.insert(ChangeRecord.makeOrphaned(entityType: "transaction", entityID: UUID(), action: "create", endpoint: "/transactions", httpMethod: "POST", payload: nil, createdAt: Date()))
        context.insert(SplitGroupModel(id: UUID(), name: "G1", createdBy: UUID(), createdAt: Date()))
        context.insert(GroupMemberModel(id: UUID(), email: "a@b.com", username: "u", joinedAt: Date()))
        context.insert(GroupTransactionModel(id: UUID(), description: "dinner", totalAmount: 30, paidBy: UUID(), createdAt: Date()))
        context.insert(GroupBalanceModel(id: UUID(), userId: UUID(), amount: 10))
        try? context.save()

        LocalDataWiper.allUserData.wipe(context: context)

        #expect((try? context.fetch(FetchDescriptor<Transaction>()))?.isEmpty == true)
        #expect((try? context.fetch(FetchDescriptor<RecurringTransaction>()))?.isEmpty == true)
        #expect((try? context.fetch(FetchDescriptor<UserBudget>()))?.isEmpty == true)
        #expect((try? context.fetch(FetchDescriptor<Money_Manager.Category>()))?.isEmpty == true)
        #expect((try? context.fetch(FetchDescriptor<ChangeRecord>()))?.isEmpty == true)
        #expect((try? context.fetch(FetchDescriptor<SplitGroupModel>()))?.isEmpty == true)
        #expect((try? context.fetch(FetchDescriptor<GroupMemberModel>()))?.isEmpty == true)
        #expect((try? context.fetch(FetchDescriptor<GroupTransactionModel>()))?.isEmpty == true)
        #expect((try? context.fetch(FetchDescriptor<GroupBalanceModel>()))?.isEmpty == true)
    }

    // MARK: - Custom wiper

    @Test func testCustomWiper_wipesOnlyRegisteredHandlers() throws {
        let context = try makeContext()
        context.insert(Transaction(amount: 10, categoryId: UUID(), date: Date()))
        context.insert(RecurringTransaction(name: "Netflix", amount: 10, categoryId: UUID(), frequency: .monthly))
        try? context.save()

        let wiper = LocalDataWiper(handlers: [TransactionWipeHandler()])
        wiper.wipe(context: context)

        #expect((try? context.fetch(FetchDescriptor<Transaction>()))?.isEmpty == true)
        #expect((try? context.fetch(FetchDescriptor<RecurringTransaction>()))?.count == 1)
    }
}

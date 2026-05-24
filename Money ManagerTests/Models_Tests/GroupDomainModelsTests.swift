import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct GroupDomainModelsTests {

    // MARK: - Helpers

    private func apiGroupWithDetails(
        id: UUID = UUID(),
        name: String = "Trip to Goa",
        createdBy: UUID = UUID(),
        createdAt: Date = Date(),
        members: [APIGroupMember] = [],
        balances: [APIGroupBalance] = []
    ) -> APIGroupWithDetails {
        APIGroupWithDetails(
            id: id, name: name, createdBy: createdBy, createdAt: createdAt,
            members: members, balances: balances
        )
    }

    private func apiGroupDetailsBody(
        id: UUID = UUID(),
        name: String = "Trip",
        createdBy: UUID = UUID(),
        createdAt: Date = Date(),
        members: [APIGroupMember] = [],
        balances: [APIGroupBalance] = [],
        settlements: [APISettlement]? = nil
    ) -> APIGroupDetailsBody {
        APIGroupDetailsBody(
            id: id, name: name, createdBy: createdBy, createdAt: createdAt,
            members: members, balances: balances, settlements: settlements
        )
    }

    private func apiGroupMember(
        id: UUID = UUID(),
        email: String = "alice@example.com",
        username: String = "Alice",
        joinedAt: Date? = Date()
    ) -> APIGroupMember {
        APIGroupMember(id: id, email: email, username: username, joinedAt: joinedAt)
    }

    private func apiGroupBalance(userId: UUID = UUID(), amount: Double = 50.0) -> APIGroupBalance {
        APIGroupBalance(userId: userId, amount: amount)
    }

    private func apiGroupTransaction(
        id: UUID = UUID(),
        groupId: UUID = UUID(),
        paidByUserId: UUID = UUID(),
        totalAmount: Double = 100.0,
        category: String = "Food",
        date: Date = Date(),
        description: String? = "Dinner",
        notes: String? = nil,
        isDeleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        splits: [APIGroupTransactionSplit] = []
    ) -> APIGroupTransaction {
        APIGroupTransaction(
            id: id, groupId: groupId, paidByUserId: paidByUserId,
            totalAmount: totalAmount, category: category, date: date,
            description: description, notes: notes, isDeleted: isDeleted,
            createdAt: createdAt, updatedAt: updatedAt, splits: splits
        )
    }

    private func apiSettlement(
        id: UUID = UUID(),
        groupId: UUID? = UUID(),
        fromUser: UUID = UUID(),
        toUser: UUID = UUID(),
        amount: Double = 25.0,
        notes: String? = nil,
        createdAt: Date = Date()
    ) -> APISettlement {
        APISettlement(
            id: id, groupId: groupId, fromUser: fromUser, toUser: toUser,
            amount: amount, notes: notes, createdAt: createdAt
        )
    }

    // MARK: - SplitGroup from APIGroupWithDetails

    @Test func testSplitGroupHappyPathFromAPIGroupWithDetails() throws {
        let dto = apiGroupWithDetails(name: "Trip to Goa")
        let group = try SplitGroup(from: dto)
        #expect(group.name == "Trip to Goa")
        #expect(group.id == dto.id)
        #expect(group.createdBy == dto.createdBy)
        #expect(group.members.isEmpty)
        #expect(group.balances.isEmpty)
        #expect(group.settlements.isEmpty)
    }

    @Test func testSplitGroupThrowsOnEmptyName() {
        let dto = apiGroupWithDetails(name: "   ")
        #expect(throws: GroupMappingError.emptyName) {
            try SplitGroup(from: dto)
        }
    }

    @Test func testSplitGroupMapsMembers() throws {
        let member = apiGroupMember(username: "Bob")
        let dto = apiGroupWithDetails(members: [member])
        let group = try SplitGroup(from: dto)
        #expect(group.members.count == 1)
        #expect(group.members.first?.username == "Bob")
    }

    @Test func testSplitGroupMapsBalances() throws {
        let balance = apiGroupBalance(amount: -30.0)
        let dto = apiGroupWithDetails(balances: [balance])
        let group = try SplitGroup(from: dto)
        #expect(group.balances.count == 1)
        #expect(group.balances.first?.amount == -30.0)
    }

    // MARK: - SplitGroup from APIGroupDetailsBody

    @Test func testSplitGroupHappyPathFromAPIGroupDetailsBody() throws {
        let settlement = apiSettlement(amount: 20.0)
        let dto = apiGroupDetailsBody(name: "Vacation", settlements: [settlement])
        let group = try SplitGroup(from: dto)
        #expect(group.name == "Vacation")
        #expect(group.settlements.count == 1)
    }

    @Test func testSplitGroupThrowsOnEmptyNameFromDetailsBody() {
        let dto = apiGroupDetailsBody(name: "")
        #expect(throws: GroupMappingError.emptyName) {
            try SplitGroup(from: dto)
        }
    }

    // MARK: - GroupMember

    @Test func testGroupMemberHappyPath() {
        let dto = apiGroupMember(email: "carol@example.com", username: "Carol", joinedAt: nil)
        let member = GroupMember(from: dto)
        #expect(member.email == "carol@example.com")
        #expect(member.username == "Carol")
        #expect(member.joinedAt == nil)
    }

    // MARK: - GroupTransaction

    @Test func testGroupTransactionHappyPath() throws {
        let split = APIGroupTransactionSplit(id: UUID(), userId: UUID(), amount: 50.0, transactionId: nil)
        let dto = apiGroupTransaction(totalAmount: 100.0, category: "Food", splits: [split])
        let tx = try GroupTransaction(from: dto)
        #expect(tx.category == "Food")
        #expect(tx.totalAmount == 100.0)
        #expect(tx.splits.count == 1)
    }

    @Test func testGroupTransactionThrowsOnEmptyCategory() {
        let dto = apiGroupTransaction(category: "")
        #expect(throws: GroupMappingError.emptyCategory) {
            try GroupTransaction(from: dto)
        }
    }

    @Test func testGroupTransactionThrowsOnWhitespaceOnlyCategory() {
        let dto = apiGroupTransaction(category: "   ")
        #expect(throws: GroupMappingError.emptyCategory) {
            try GroupTransaction(from: dto)
        }
    }

    @Test func testGroupTransactionThrowsOnNegativeAmount() {
        let dto = apiGroupTransaction(totalAmount: -1.0)
        #expect(throws: GroupMappingError.invalidAmount) {
            try GroupTransaction(from: dto)
        }
    }

    @Test func testGroupTransactionPreservesOptionalFields() throws {
        let dto = apiGroupTransaction(description: "Lunch", notes: "Split evenly", isDeleted: true)
        let tx = try GroupTransaction(from: dto)
        #expect(tx.description == "Lunch")
        #expect(tx.notes == "Split evenly")
        #expect(tx.isDeleted == true)
    }

    // MARK: - Settlement

    @Test func testSettlementHappyPath() {
        let dto = apiSettlement(amount: 50.0, notes: "Paid back")
        let settlement = Settlement(from: dto)
        #expect(settlement.amount == 50.0)
        #expect(settlement.notes == "Paid back")
        #expect(settlement.groupId != nil)
    }

    @Test func testSettlementWithNilGroupId() {
        let dto = apiSettlement(groupId: nil, amount: 10.0)
        let settlement = Settlement(from: dto)
        #expect(settlement.groupId == nil)
    }
}

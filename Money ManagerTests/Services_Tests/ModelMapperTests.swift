import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct ModelMapperTests {

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private func makeAPITransaction(
        id: UUID,
        type: String = "expense",
        amount: Double = 100,
        category: String = "Food",
        isDeleted: Bool = false
    ) throws -> APITransaction {
        let json = """
        {
            "id": "\(id.uuidString)",
            "user_id": "\(UUID().uuidString)",
            "type": "\(type)",
            "amount": \(amount),
            "category": "\(category)",
            "date": "2024-06-01T00:00:00Z",
            "is_deleted": \(isDeleted),
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-06-01T00:00:00Z"
        }
        """.data(using: .utf8)!
        return try Self.decoder.decode(APITransaction.self, from: json)
    }

    private func makeAPIRecurring(
        id: UUID,
        frequency: String = "monthly",
        type: String? = nil
    ) throws -> APIRecurringTransaction {
        let typeField = type.map { "\"type\": \"\($0)\"," } ?? ""
        let json = """
        {
            "id": "\(id.uuidString)",
            "user_id": "\(UUID().uuidString)",
            "name": "Netflix",
            "amount": 500,
            "category": "Entertainment",
            "frequency": "\(frequency)",
            "start_date": "2024-01-01T00:00:00Z",
            "is_active": true,
            \(typeField)
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-06-01T00:00:00Z"
        }
        """.data(using: .utf8)!
        return try Self.decoder.decode(APIRecurringTransaction.self, from: json)
    }

    // MARK: - Transaction.applyRemote

    @Test
    func testApplyRemoteOverwritesTransactionFields() throws {
        let transaction = Transaction(amount: 100, category: "Food", date: Date())
        let api = try makeAPITransaction(id: transaction.id, type: "income", amount: 500, category: "Transport")

        transaction.applyRemote(api)

        #expect(transaction.type == .income)
        #expect(transaction.amount == 500)
        #expect(transaction.category == "Transport")
    }

    @Test
    func testApplyRemoteSetsIsSoftDeletedFromIsDeleted() throws {
        let transaction = Transaction(amount: 100, category: "Food", date: Date())
        #expect(transaction.isSoftDeleted == false)

        let api = try makeAPITransaction(id: transaction.id, isDeleted: true)
        transaction.applyRemote(api)

        #expect(transaction.isSoftDeleted == true)
    }

    @Test
    func testApplyRemoteFallsBackToExistingTypeOnUnknownRawValue() throws {
        let transaction = Transaction(type: .income, amount: 100, category: "Food", date: Date())
        let api = try makeAPITransaction(id: transaction.id, type: "unknown_type")

        transaction.applyRemote(api)

        // "unknown_type" has no matching TransactionKind case — should keep existing .income
        #expect(transaction.type == .income)
    }

    // MARK: - RecurringTransaction.applyRemote

    @Test
    func testApplyRemoteRecurringHandlesNilType() throws {
        let recurring = RecurringTransaction(name: "Netflix", amount: 500, category: "Entertainment", frequency: .monthly)
        recurring.type = .expense

        let api = try makeAPIRecurring(id: recurring.id, type: nil)
        recurring.applyRemote(api)

        // nil type should not change existing type
        #expect(recurring.type == .expense)
    }

    @Test
    func testApplyRemoteRecurringFallsBackToExistingFrequencyOnUnknownValue() throws {
        let recurring = RecurringTransaction(name: "Gym", amount: 1000, category: "Health", frequency: .monthly)

        let api = try makeAPIRecurring(id: recurring.id, frequency: "biweekly")
        recurring.applyRemote(api)

        // "biweekly" is not a valid RecurringFrequency — should keep .monthly
        #expect(recurring.frequency == .monthly)
    }

    @Test
    func testApplyRemoteRecurringUpdatesTypeWhenValid() throws {
        let recurring = RecurringTransaction(name: "Salary", amount: 5000, category: "Work & Professional", frequency: .monthly)
        recurring.type = .expense

        let api = try makeAPIRecurring(id: recurring.id, type: "income")
        recurring.applyRemote(api)

        #expect(recurring.type == .income)
    }

    // MARK: - toCreateRequest spot checks

    @Test
    func testTransactionToCreateRequestIncludesId() {
        let transaction = Transaction(amount: 250, category: "Food", date: Date())
        let request = transaction.toCreateRequest()
        #expect(request.id == transaction.id)
    }

    @Test
    func testRecurringTransactionToCreateRequestIncludesIdAndFrequency() {
        let recurring = RecurringTransaction(name: "Netflix", amount: 500, category: "Entertainment", frequency: .monthly)
        let request = recurring.toCreateRequest()
        #expect(request.id == recurring.id)
        #expect(request.frequency == "monthly")
    }
}

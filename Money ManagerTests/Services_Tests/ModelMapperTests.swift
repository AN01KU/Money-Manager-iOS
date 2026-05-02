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

    // MARK: - Transaction.toUpdateRequest

    @Test
    func testTransactionToUpdateRequestIncludesFields() {
        let tx = Transaction(amount: 250, category: "Transport", date: Date(), transactionDescription: "Bus fare")
        let req = tx.toUpdateRequest()
        #expect(req.amount == 250)
        #expect(req.category == "Transport")
        #expect(req.description == "Bus fare")
        #expect(req.type == "expense")
    }

    // MARK: - RecurringTransaction.toUpdateRequest

    @Test
    func testRecurringTransactionToUpdateRequestIncludesFields() {
        let recurring = RecurringTransaction(name: "Gym", amount: 500, category: "Health", frequency: .weekly, isActive: false, type: .expense)
        let req = recurring.toUpdateRequest()
        #expect(req.name == "Gym")
        #expect(req.amount == 500)
        #expect(req.frequency == "weekly")
        #expect(req.isActive == false)
    }

    // MARK: - MonthlyBudget mappers

    @Test
    func testMonthlyBudgetToCreateRequestIncludesFields() {
        let budget = MonthlyBudget(year: 2024, month: 6, limit: 5000)
        let req = budget.toCreateRequest()
        #expect(req.year == 2024)
        #expect(req.month == 6)
        #expect(req.limit == 5000)
        #expect(req.id == budget.id)
    }

    @Test
    func testMonthlyBudgetToUpdateRequestIncludesFields() {
        let budget = MonthlyBudget(year: 2024, month: 6, limit: 8000)
        let req = budget.toUpdateRequest()
        #expect(req.year == 2024)
        #expect(req.month == 6)
        #expect(req.limit == 8000)
    }

    @Test
    func testMonthlyBudgetApplyRemoteUpdatesFields() throws {
        let budget = MonthlyBudget(year: 2024, month: 1, limit: 1000)
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "user_id": "\(UUID().uuidString)",
            "year": 2024,
            "month": 6,
            "limit": 9000,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-06-01T00:00:00Z"
        }
        """.data(using: .utf8)!
        let api = try Self.decoder.decode(APIMonthlyBudget.self, from: json)
        budget.applyRemote(api)
        #expect(budget.month == 6)
        #expect(budget.limit == 9000)
    }

    // MARK: - CustomCategory mappers

    @Test
    func testCustomCategoryToCreateRequestIncludesFields() {
        let cat = CustomCategory(name: "Fitness", icon: "🏋️", color: "#FF0000", isPredefined: false)
        let req = cat.toCreateRequest()
        #expect(req.name == "Fitness")
        #expect(req.icon == "🏋️")
        #expect(req.color == "#FF0000")
        #expect(req.id == cat.id)
    }

    @Test
    func testCustomCategoryToUpdateRequestIncludesFields() {
        let cat = CustomCategory(name: "Fitness", icon: "🏋️", color: "#00FF00", isPredefined: false)
        cat.isHidden = true
        let req = cat.toUpdateRequest()
        #expect(req.name == "Fitness")
        #expect(req.isHidden == true)
        #expect(req.color == "#00FF00")
    }

    @Test
    func testCustomCategoryApplyRemoteUpdatesFields() throws {
        let cat = CustomCategory(name: "Old", icon: "⬛️", color: "#000000", isPredefined: false)
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "user_id": "\(UUID().uuidString)",
            "key": "fitness-custom",
            "name": "Fitness",
            "icon": "🏋️",
            "color": "#FF0000",
            "is_hidden": false,
            "is_predefined": false,
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-06-01T00:00:00Z"
        }
        """.data(using: .utf8)!
        let api = try Self.decoder.decode(APICustomCategory.self, from: json)
        cat.applyRemote(api)
        #expect(cat.name == "Fitness")
        #expect(cat.icon == "🏋️")
        #expect(cat.color == "#FF0000")
    }

    // MARK: - Transaction.applyRemote — group/settlement fields

    @Test
    func testApplyRemoteSetsGroupAndSettlementIds() throws {
        let transaction = Transaction(amount: 100, category: "Food", date: Date())
        let groupTxId = UUID()
        let settlementId = UUID()
        let groupId = UUID()

        let json = """
        {
            "id": "\(transaction.id.uuidString)",
            "user_id": "\(UUID().uuidString)",
            "type": "expense",
            "amount": 100,
            "category": "Food",
            "date": "2024-06-01T00:00:00Z",
            "is_deleted": false,
            "group_transaction_id": "\(groupTxId.uuidString)",
            "settlement_id": "\(settlementId.uuidString)",
            "group_id": "\(groupId.uuidString)",
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-06-01T00:00:00Z"
        }
        """.data(using: .utf8)!
        let api = try Self.decoder.decode(APITransaction.self, from: json)
        transaction.applyRemote(api)

        #expect(transaction.groupTransactionId == groupTxId)
        #expect(transaction.settlementId == settlementId)
        #expect(transaction.groupId == groupId)
    }

    @Test
    func testApplyRemoteSetsRecurringExpenseId() throws {
        let transaction = Transaction(amount: 100, category: "Food", date: Date())
        let recurringId = UUID()

        let json = """
        {
            "id": "\(transaction.id.uuidString)",
            "user_id": "\(UUID().uuidString)",
            "type": "expense",
            "amount": 100,
            "category": "Food",
            "date": "2024-06-01T00:00:00Z",
            "is_deleted": false,
            "recurring_transaction_id": "\(recurringId.uuidString)",
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-06-01T00:00:00Z"
        }
        """.data(using: .utf8)!
        let api = try Self.decoder.decode(APITransaction.self, from: json)
        transaction.applyRemote(api)

        #expect(transaction.recurringExpenseId == recurringId)
    }
}

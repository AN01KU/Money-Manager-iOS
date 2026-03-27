import Foundation
import Testing
@testable import Money_Manager

@Suite(.serialized)
@MainActor
struct APIIntegrationTests {
    
    private let testPassword: String = "Test123!"
    private static var authEmail: String = ""
    private static var authToken: String = ""
    
    init() {
        APIClient.shared.setTestToken(Self.authToken.isEmpty ? nil : Self.authToken)
    }
    
    private func delay(_ ms: Int = 100) async {
        try? await Task.sleep(nanoseconds: UInt64(ms * 1_000_000))
    }
    
    private func compareAmount(_ a: String, _ b: String) -> Bool {
        guard let decimalA = Decimal(string: a),
              let decimalB = Decimal(string: b) else { return false }
        return decimalA == decimalB
    }
    
    private func ensureAuthenticated() async throws {
        if Self.authToken.isEmpty {
            await delay(200)
            
            let email = "api_\(UUID().uuidString.prefix(8))@test.com"
            let username = "user_\(UUID().uuidString.prefix(8))"
            
            let signupRequest = APISignupRequest(email: email, username: username, password: testPassword)
            let signupResponse: APIAuthResponse = try await APIClient.shared.post("/auth/signup", body: signupRequest)
            
            Self.authToken = signupResponse.token
            Self.authEmail = email
            APIClient.shared.setTestToken(Self.authToken)
        } else {
            APIClient.shared.setTestToken(Self.authToken)
        }
    }
    
    // MARK: - Auth Tests
    
    @Test("Signup creates user and returns token")
    mutating func testAuthSignup() async throws {
        let email = "api_\(UUID().uuidString.prefix(8))@test.com"
        let username = "user_\(UUID().uuidString.prefix(8))"
        
        let request = APISignupRequest(email: email, username: username, password: testPassword)
        let response: APIAuthResponse = try await APIClient.shared.post("/auth/signup", body: request)
        
        #expect(!response.token.isEmpty)
        #expect(response.user.email == email)
        
        Self.authToken = response.token
        Self.authEmail = email
        APIClient.shared.setTestToken(response.token)
    }
    
    // MARK: - Category Tests
    
    @Test("Create category returns 201")
    mutating func testCategoryCreate() async throws {
        try await ensureAuthenticated()
        await delay(200)
        
        let request = APICreateCategoryRequest(
            id: nil,
            name: "Test Cat \(UUID().uuidString.prefix(8))",
            icon: "star.circle.fill",
            color: "#FF5733"
        )
        let response: APICustomCategory = try await APIClient.shared.post("/categories", body: request)
        
        #expect(response.name == request.name)
    }
    
    @Test("List categories returns array")
    mutating func testCategoryList() async throws {
        try await ensureAuthenticated()
        await delay(200)
        
        let response: APIListResponse<APICustomCategory> = try await APIClient.shared.get("/categories")

        #expect(!response.data.isEmpty)
    }
    
    @Test("Update category modifies data")
    mutating func testCategoryUpdate() async throws {
        try await ensureAuthenticated()
        await delay(200)
        
        let createRequest = APICreateCategoryRequest(
            id: nil,
            name: "Update Test \(UUID().uuidString.prefix(8))",
            icon: "star.fill",
            color: "#FF5733"
        )
        let created: APICustomCategory = try await APIClient.shared.post("/categories", body: createRequest)
        
        await delay(200)
        
        let updateName = "Updated \(UUID().uuidString.prefix(4))"
        let updateRequest = APIUpdateCategoryRequest(name: updateName, icon: "heart.fill", color: nil, is_hidden: nil)
        let updated: APICustomCategory = try await APIClient.shared.put("/categories/\(created.id)", body: updateRequest)
        
        #expect(updated.name == updateName)
    }
    
    @Test("Delete category removes it")
    mutating func testCategoryDelete() async throws {
        try await ensureAuthenticated()
        await delay(200)
        
        let createRequest = APICreateCategoryRequest(
            id: nil,
            name: "Delete Me \(UUID().uuidString.prefix(8))",
            icon: "trash.fill",
            color: "#FF5733"
        )
        let created: APICustomCategory = try await APIClient.shared.post("/categories", body: createRequest)
        
        await delay(200)
        
        let _: APIMessageResponse = try await APIClient.shared.deleteMessage("/categories/\(created.id)")
        
        await delay(200)
        
        let categories: APIListResponse<APICustomCategory> = try await APIClient.shared.get("/categories")
        #expect(!categories.data.contains(where: { $0.id == created.id }))
    }
    
    // MARK: - Budget Tests
    
    @Test("Create budget returns 200/201")
    mutating func testBudgetCreate() async throws {
        try await ensureAuthenticated()
        await delay(200)
        
        let request = APICreateBudgetRequest(id: nil, year: 2026, month: 12, limit: "5000.00")
        let response: APIMonthlyBudget = try await APIClient.shared.post("/budgets", body: request)
        
        #expect(compareAmount(response.limit, request.limit))
    }
    
    @Test("List budgets returns data array")
    mutating func testBudgetList() async throws {
        try await ensureAuthenticated()
        await delay(200)
        
        let response: APIListResponse<APIMonthlyBudget> = try await APIClient.shared.get("/budgets")
        
        #expect(!response.data.isEmpty)
    }
    
    @Test("Update budget modifies limit")
    mutating func testBudgetUpdate() async throws {
        try await ensureAuthenticated()
        await delay(200)
        
        let createRequest = APICreateBudgetRequest(id: nil, year: 2026, month: 9, limit: "1000.00")
        let created: APIMonthlyBudget = try await APIClient.shared.post("/budgets", body: createRequest)
        
        await delay(200)
        
        let updateRequest = APIUpdateBudgetRequest(year: nil, month: nil, limit: "1500.00")
        let updated: APIMonthlyBudget = try await APIClient.shared.put("/budgets/\(created.id)", body: updateRequest)
        
        #expect(compareAmount(updated.limit, "1500"))
    }
    
    @Test("Delete budget removes it")
    mutating func testBudgetDelete() async throws {
        try await ensureAuthenticated()
        await delay(200)
        
        let request = APICreateBudgetRequest(id: nil, year: 2025, month: 12, limit: "999.00")
        let created: APIMonthlyBudget = try await APIClient.shared.post("/budgets", body: request)
        
        await delay(200)
        
        try await APIClient.shared.delete("/budgets/\(created.id)")
    }
    
    // MARK: - Recurring Expense Tests
    
    @Test("Create monthly recurring expense")
    mutating func testRecurringExpenseCreateMonthly() async throws {
        try await ensureAuthenticated()
        await delay(200)
        
        let startDate = ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z")!
        let request = APICreateRecurringExpenseRequest(
            id: nil,
            name: "Netflix \(UUID().uuidString.prefix(4))",
            amount: "15.99",
            category: "Entertainment",
            frequency: "monthly",
            day_of_month: 15,
            days_of_week: nil,
            start_date: startDate,
            end_date: nil,
            is_active: true,
            notes: nil
        )
        
        let response: APIRecurringExpense = try await APIClient.shared.post("/recurring-expenses", body: request)
        
        #expect(response.name == request.name)
        #expect(compareAmount(response.amount, request.amount))
    }
    
    @Test("Create weekly recurring expense")
    mutating func testRecurringExpenseCreateWeekly() async throws {
        try await ensureAuthenticated()
        await delay(200)
        
        let startDate = ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z")!
        let request = APICreateRecurringExpenseRequest(
            id: nil,
            name: "Gym \(UUID().uuidString.prefix(4))",
            amount: "50.00",
            category: "Health & Medical",
            frequency: "weekly",
            day_of_month: nil,
            days_of_week: [1, 3, 5],
            start_date: startDate,
            end_date: nil,
            is_active: true,
            notes: nil
        )
        
        let response: APIRecurringExpense = try await APIClient.shared.post("/recurring-expenses", body: request)
        
        #expect(response.frequency == "weekly")
        #expect(response.days_of_week == [1, 3, 5])
        #expect(compareAmount(response.amount, request.amount))
    }
    
    @Test("List recurring expenses")
    mutating func testRecurringExpenseList() async throws {
        try await ensureAuthenticated()
        await delay(200)
        
        let response: APIListResponse<APIRecurringExpense> = try await APIClient.shared.get("/recurring-expenses")

        #expect(!response.data.isEmpty)
    }
    
    @Test("Get recurring expense by id")
    mutating func testRecurringExpenseGetById() async throws {
        try await ensureAuthenticated()
        await delay(200)
        
        let startDate = ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z")!
        let createRequest = APICreateRecurringExpenseRequest(
            id: nil,
            name: "Get Test \(UUID().uuidString.prefix(4))",
            amount: "5.00",
            category: "Other",
            frequency: "monthly",
            day_of_month: 20,
            days_of_week: nil,
            start_date: startDate,
            end_date: nil,
            is_active: true,
            notes: nil
        )
        let created: APIRecurringExpense = try await APIClient.shared.post("/recurring-expenses", body: createRequest)
        
        await delay(200)
        
        let response: APIRecurringExpense = try await APIClient.shared.get("/recurring-expenses/\(created.id)")
        
        #expect(response.id == created.id)
    }
    
    @Test("Update recurring expense")
    mutating func testRecurringExpenseUpdate() async throws {
        try await ensureAuthenticated()
        await delay(200)
        
        let startDate = ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z")!
        let createRequest = APICreateRecurringExpenseRequest(
            id: nil,
            name: "Update Test \(UUID().uuidString.prefix(4))",
            amount: "10.00",
            category: "Entertainment",
            frequency: "monthly",
            day_of_month: 5,
            days_of_week: nil,
            start_date: startDate,
            end_date: nil,
            is_active: true,
            notes: nil
        )
        let created: APIRecurringExpense = try await APIClient.shared.post("/recurring-expenses", body: createRequest)
        
        await delay(200)
        
        let updateRequest = APIUpdateRecurringExpenseRequest(
            name: nil, amount: "12.00", category: nil, frequency: nil,
            day_of_month: nil, days_of_week: nil, start_date: nil, end_date: nil,
            is_active: false, notes: nil
        )
        let updated: APIRecurringExpense = try await APIClient.shared.put("/recurring-expenses/\(created.id)", body: updateRequest)
        
        #expect(compareAmount(updated.amount, "12"))
        #expect(updated.is_active == false)
    }
    
    @Test("Delete recurring expense")
    mutating func testRecurringExpenseDelete() async throws {
        try await ensureAuthenticated()
        await delay(200)
        
        let startDate = ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z")!
        let createRequest = APICreateRecurringExpenseRequest(
            id: nil,
            name: "Delete Test \(UUID().uuidString.prefix(4))",
            amount: "8.00",
            category: "Other",
            frequency: "monthly",
            day_of_month: 10,
            days_of_week: nil,
            start_date: startDate,
            end_date: nil,
            is_active: true,
            notes: nil
        )
        let created: APIRecurringExpense = try await APIClient.shared.post("/recurring-expenses", body: createRequest)
        
        await delay(200)
        
        try await APIClient.shared.delete("/recurring-expenses/\(created.id)")
    }
    
    // MARK: - Transaction Tests

    @Test("Create expense transaction")
    mutating func testTransactionCreateExpense() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let request = APICreateTransactionRequest(
            id: nil,
            type: "expense",
            amount: "25.50",
            category: "Food & Dining",
            date: Date(),
            time: nil,
            description: "Test lunch",
            notes: nil,
            recurring_expense_id: nil
        )

        let response: APITransaction = try await APIClient.shared.post("/transactions", body: request)

        #expect(compareAmount(response.amount, request.amount))
        #expect(response.category == request.category)
        #expect(response.type == "expense")
        #expect(response.group_transaction_id == nil)
    }

    @Test("Create income transaction")
    mutating func testTransactionCreateIncome() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let request = APICreateTransactionRequest(
            id: nil,
            type: "income",
            amount: "5000.00",
            category: "Work & Professional",
            date: Date(),
            time: nil,
            description: "Monthly salary",
            notes: nil,
            recurring_expense_id: nil
        )

        let response: APITransaction = try await APIClient.shared.post("/transactions", body: request)

        #expect(compareAmount(response.amount, request.amount))
        #expect(response.type == "income")
    }

    @Test("Create transaction with notes and time")
    mutating func testTransactionCreateWithNotesAndTime() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let request = APICreateTransactionRequest(
            id: nil,
            type: "expense",
            amount: "45.00",
            category: "Shopping",
            date: Date(),
            time: ISO8601DateFormatter().date(from: "2026-03-22T14:30:00Z"),
            description: "Groceries",
            notes: "Weekly shopping",
            recurring_expense_id: nil
        )

        let response: APITransaction = try await APIClient.shared.post("/transactions", body: request)

        #expect(compareAmount(response.amount, request.amount))
        #expect(response.description == request.description)
        #expect(response.notes == request.notes)
    }

    @Test("List transactions returns paginated response")
    mutating func testTransactionListPaginated() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let response: APIPaginatedResponse<APITransaction> = try await APIClient.shared.get("/transactions")

        #expect(!response.data.isEmpty)
    }

    @Test("List transactions filtered by type=expense")
    mutating func testTransactionListFilteredByExpense() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let response: APIPaginatedResponse<APITransaction> = try await APIClient.shared.get(
            "/transactions",
            queryItems: [URLQueryItem(name: "type", value: "expense")]
        )

        #expect(response.data.allSatisfy { $0.type == "expense" })
    }

    @Test("List transactions filtered by type=income")
    mutating func testTransactionListFilteredByIncome() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let response: APIPaginatedResponse<APITransaction> = try await APIClient.shared.get(
            "/transactions",
            queryItems: [URLQueryItem(name: "type", value: "income")]
        )

        #expect(response.data.allSatisfy { $0.type == "income" })
    }

    @Test("Get transaction by id")
    mutating func testTransactionGetById() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let createRequest = APICreateTransactionRequest(
            id: nil,
            type: "expense",
            amount: "100.00",
            category: "Transport",
            date: Date(),
            time: nil,
            description: "Taxi",
            notes: nil,
            recurring_expense_id: nil
        )
        let created: APITransaction = try await APIClient.shared.post("/transactions", body: createRequest)

        await delay(200)

        let response: APITransaction = try await APIClient.shared.get("/transactions/\(created.id)")

        #expect(response.id == created.id)
        #expect(response.type == "expense")
    }

    @Test("Update transaction modifies data")
    mutating func testTransactionUpdate() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let createRequest = APICreateTransactionRequest(
            id: nil,
            type: "expense",
            amount: "50.00",
            category: "Food & Dining",
            date: Date(),
            time: nil,
            description: "Before update",
            notes: nil,
            recurring_expense_id: nil
        )
        let created: APITransaction = try await APIClient.shared.post("/transactions", body: createRequest)

        await delay(200)

        let updateRequest = APIUpdateTransactionRequest(
            type: nil,
            amount: "55.00",
            category: nil,
            date: nil,
            time: nil,
            description: "After update",
            notes: nil
        )
        let updated: APITransaction = try await APIClient.shared.patch("/transactions/\(created.id)", body: updateRequest)

        #expect(compareAmount(updated.amount, "55"))
        #expect(updated.description == "After update")
    }

    @Test("Delete transaction soft deletes")
    mutating func testTransactionDelete() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let createRequest = APICreateTransactionRequest(
            id: nil,
            type: "expense",
            amount: "75.00",
            category: "Shopping",
            date: Date(),
            time: nil,
            description: "To be deleted",
            notes: nil,
            recurring_expense_id: nil
        )
        let created: APITransaction = try await APIClient.shared.post("/transactions", body: createRequest)

        await delay(200)

        try await APIClient.shared.delete("/transactions/\(created.id)")

        await delay(200)

        let response: APITransaction = try await APIClient.shared.get("/transactions/\(created.id)")
        #expect(response.is_deleted == true)
    }

    // MARK: - Group Transaction Tests

    @Test("Create group and add group transaction")
    mutating func testGroupTransactionCreate() async throws {
        try await ensureAuthenticated()
        await delay(200)

        // POST /groups returns a bare APIGroup (no members inline)
        let groupRequest = APICreateGroupRequest(name: "Test Group \(UUID().uuidString.prefix(4))")
        let group: APIGroup = try await APIClient.shared.post("/groups", body: groupRequest)

        await delay(200)

        // Fetch members separately
        let membersResponse: APIListResponse<APIGroupMember> = try await APIClient.shared.get("/groups/\(group.id)/members")
        guard let member = membersResponse.data.first else {
            Issue.record("Group has no members")
            return
        }

        let txRequest = APICreateGroupTransactionRequest(
            paid_by_user_id: member.id,
            total_amount: "90.00",
            category: "Food & Dining",
            date: Date(),
            description: "Group dinner",
            notes: nil,
            splits: [
                APIGroupTransactionSplitInput(user_id: member.id, amount: "90.00")
            ]
        )

        let response: APIGroupTransaction = try await APIClient.shared.post(
            "/groups/\(group.id)/transactions",
            body: txRequest
        )

        #expect(compareAmount(response.total_amount, "90.00"))
        #expect(response.category == "Food & Dining")
        #expect(response.paid_by_user_id == member.id)
        #expect(!response.splits.isEmpty)
    }

    @Test("List group transactions")
    mutating func testGroupTransactionList() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let groupRequest = APICreateGroupRequest(name: "List Test \(UUID().uuidString.prefix(4))")
        let group: APIGroup = try await APIClient.shared.post("/groups", body: groupRequest)

        await delay(200)

        let membersResponse: APIListResponse<APIGroupMember> = try await APIClient.shared.get("/groups/\(group.id)/members")
        guard let member = membersResponse.data.first else {
            Issue.record("Group has no members")
            return
        }

        let txRequest = APICreateGroupTransactionRequest(
            paid_by_user_id: member.id,
            total_amount: "30.00",
            category: "Transport",
            date: Date(),
            description: "Cab ride",
            notes: nil,
            splits: [
                APIGroupTransactionSplitInput(user_id: member.id, amount: "30.00")
            ]
        )
        let _: APIGroupTransaction = try await APIClient.shared.post("/groups/\(group.id)/transactions", body: txRequest)

        await delay(200)

        struct GroupTransactionsResponse: Codable { let data: [APIGroupTransaction] }
        let response: GroupTransactionsResponse = try await APIClient.shared.get("/groups/\(group.id)/transactions")

        #expect(!response.data.isEmpty)
    }
    
    // MARK: - Dashboard Tests
    
    @Test("Dashboard monthly returns overview")
    mutating func testDashboardMonthly() async throws {
        try await ensureAuthenticated()
        await delay(200)
        
        let month = Calendar.current.component(.month, from: Date())
        let year = Calendar.current.component(.year, from: Date())
        
        let response: APIMonthlyDashboardResponse = try await APIClient.shared.get("/dashboard/monthly", queryItems: [
            URLQueryItem(name: "month", value: "\(month)"),
            URLQueryItem(name: "year", value: "\(year)")
        ])
        
        #expect(response.totalExpenses != nil || response.total_expenses != nil)
    }
    
    // MARK: - Cleanup
    
    @Test("Cleanup: delete test user")
    func testCleanupDeleteUser() async throws {
        guard !Self.authToken.isEmpty else { return }
        await delay(200)
        try await APIClient.shared.delete("/me")
    }
}

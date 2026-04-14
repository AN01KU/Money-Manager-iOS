import APIClient
import Foundation
import Testing
@testable import Money_Manager

@Suite(.serialized)
@MainActor
struct APIIntegrationTests {

    private let testPassword: String = "Test123!"
    private static var authEmail: String = ""
    private static var authToken: String = ""
    private static var authSyncSessionID: UUID? = nil

    init() {
        AppAPIClient.shared.setTestToken(Self.authToken.isEmpty ? nil : Self.authToken)
        if let sid = Self.authSyncSessionID {
            AppAPIClient.shared.setTestSyncSessionID(sid)
        }
    }

    private func delay(_ ms: Int = 100) async {
        try? await Task.sleep(nanoseconds: UInt64(ms * 1_000_000))
    }

    private func compareAmount(_ a: Double, _ b: Double) -> Bool {
        abs(a - b) < 0.001
    }

    private func ensureAuthenticated() async throws {
        if Self.authToken.isEmpty {
            await delay(200)

            let email = "api_\(UUID().uuidString.prefix(8))@test.com"
            let username = "user_\(UUID().uuidString.prefix(8))"

            let signupRequest = APISignupRequest(email: email, username: username, password: testPassword, inviteCode: "FIN-INVITE-2026")
            let signupResponse: APIAuthResponse = try await AppAPIClient.shared.post(.raw("/auth/signup"), body: signupRequest)

            Self.authToken = signupResponse.token
            Self.authSyncSessionID = signupResponse.syncSessionId
            Self.authEmail = email
            AppAPIClient.shared.setTestToken(Self.authToken)
            AppAPIClient.shared.setTestSyncSessionID(signupResponse.syncSessionId)
        } else {
            AppAPIClient.shared.setTestToken(Self.authToken)
            if let sid = Self.authSyncSessionID {
                AppAPIClient.shared.setTestSyncSessionID(sid)
            }
        }
    }

    // MARK: - Auth Tests

    @Test("Signup creates user and returns token")
    mutating func testAuthSignup() async throws {
        let email = "api_\(UUID().uuidString.prefix(8))@test.com"
        let username = "user_\(UUID().uuidString.prefix(8))"

        let request = APISignupRequest(email: email, username: username, password: testPassword, inviteCode: "FIN-INVITE-2026")
        let response: APIAuthResponse = try await AppAPIClient.shared.post(.raw("/auth/signup"), body: request)

        #expect(!response.token.isEmpty)
        #expect(response.user.email == email)
        #expect(response.syncSessionId != UUID(uuid: (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)))

        Self.authToken = response.token
        Self.authSyncSessionID = response.syncSessionId
        Self.authEmail = email
        AppAPIClient.shared.setTestToken(response.token)
        AppAPIClient.shared.setTestSyncSessionID(response.syncSessionId)
    }

    @Test("Preflight returns valid for fresh sync session")
    mutating func testSyncPreflightValidForFreshSession() async throws {
        try await ensureAuthenticated()
        await delay(200)

        guard let sessionID = Self.authSyncSessionID else {
            Issue.record("No sync session ID available — ensure testAuthSignup ran first")
            return
        }

        let body = APISyncPreflightRequest(syncSessionId: sessionID)
        let response: APISyncPreflightResponse = try await AppAPIClient.shared.post(.raw("/sync/preflight"), body: body)

        #expect(response.valid == true)
        #expect(response.reason == nil)
    }

    // MARK: - Category Tests

    @Test("Create custom category returns correct fields")
    mutating func testCategoryCreate() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let request = APICreateCategoryRequest(
            id: nil,
            name: "Test Cat \(UUID().uuidString.prefix(8))",
            icon: "star.circle.fill",
            color: "#FF5733",
            isHidden: nil,
            isPredefined: nil,
            predefinedKey: nil
        )
        let response: APICustomCategory = try await AppAPIClient.shared.post(.raw("/categories"), body: request)

        #expect(response.name == request.name)
        #expect(response.icon == request.icon)
        #expect(response.color == request.color)
        #expect(response.isHidden == false)
        #expect(response.isPredefined == false)
        #expect(response.predefinedKey == nil)
    }

    @Test("Create predefined override returns isPredefined=true and predefinedKey")
    mutating func testCategoryCreatePredefinedOverride() async throws {
        try await ensureAuthenticated()
        await delay(200)

        // Simulate the client sending a predefined override (e.g. user renamed Food & Dining)
        // Backend should store this as an override row with isPredefined=true
        struct APIPredefinedOverrideRequest: Codable {
            let id: UUID?
            let name: String
            let icon: String
            let color: String
            let predefined_key: String
        }

        let request = APIPredefinedOverrideRequest(
            id: nil,
            name: "Eating Out",
            icon: "fork.knife.circle.fill",
            color: "#FF6B6B",
            predefined_key: "foodDining"
        )
        let response: APICustomCategory = try await AppAPIClient.shared.post(.raw("/categories"), body: request)

        #expect(response.name == "Eating Out")
        #expect(response.isPredefined == true)
        #expect(response.predefinedKey == "foodDining")
    }

    @Test("Fresh user gets exactly 15 predefined categories with no custom ones")
    mutating func testCategoryListFreshUserGetsPredefinedDefaults() async throws {
        // Sign up a brand-new user — no customisations yet
        await delay(200)
        let email = "api_\(UUID().uuidString.prefix(8))@test.com"
        let username = "user_\(UUID().uuidString.prefix(8))"
        let signupRequest = APISignupRequest(email: email, username: username, password: testPassword, inviteCode: "FIN-INVITE-2026")
        let signupResponse: APIAuthResponse = try await AppAPIClient.shared.post(.raw("/auth/signup"), body: signupRequest)
        AppAPIClient.shared.setTestToken(signupResponse.token)

        await delay(200)

        let response: APIListResponse<APICustomCategory> = try await AppAPIClient.shared.get(.raw("/categories"))

        // New architecture: no DB seeding — backend returns 15 predefined categories in-memory
        #expect(response.data.count == 15)
        #expect(response.data.allSatisfy { $0.isPredefined == true })
        #expect(response.data.allSatisfy { $0.predefinedKey != nil })

        // Cleanup
        try await AppAPIClient.shared.delete(.raw("/me"))
        AppAPIClient.shared.setTestToken(Self.authToken)
    }

    @Test("List categories returns created custom categories")
    mutating func testCategoryListAfterCreating() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let name = "ListTest \(UUID().uuidString.prefix(8))"
        let request = APICreateCategoryRequest(id: nil, name: name, icon: "star.circle.fill", color: "#4ECDC4", isHidden: nil, isPredefined: nil, predefinedKey: nil)
        let _: APICustomCategory = try await AppAPIClient.shared.post(.raw("/categories"), body: request)

        await delay(200)

        let response: APIListResponse<APICustomCategory> = try await AppAPIClient.shared.get(.raw("/categories"))

        #expect(response.data.contains(where: { $0.name == name }))
    }

    @Test("List categories response includes isPredefined and predefinedKey fields")
    mutating func testCategoryListResponseShape() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let request = APICreateCategoryRequest(
            id: nil,
            name: "Shape Test \(UUID().uuidString.prefix(8))",
            icon: "tag.circle.fill",
            color: "#8E44AD",
            isHidden: nil,
            isPredefined: nil,
            predefinedKey: nil
        )
        let created: APICustomCategory = try await AppAPIClient.shared.post(.raw("/categories"), body: request)

        await delay(200)

        let response: APIListResponse<APICustomCategory> = try await AppAPIClient.shared.get(.raw("/categories"))
        let found = response.data.first(where: { $0.id == created.id })

        #expect(found != nil)
        #expect(found?.isPredefined == false)
        #expect(found?.predefinedKey == nil)
        #expect(found?.isHidden == false)
    }

    @Test("Update category modifies name and icon")
    mutating func testCategoryUpdate() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let createRequest = APICreateCategoryRequest(
            id: nil,
            name: "Update Test \(UUID().uuidString.prefix(8))",
            icon: "star.fill",
            color: "#FF5733",
            isHidden: nil,
            isPredefined: nil,
            predefinedKey: nil
        )
        let created: APICustomCategory = try await AppAPIClient.shared.post(.raw("/categories"), body: createRequest)

        await delay(200)

        let updateName = "Updated \(UUID().uuidString.prefix(4))"
        let updateRequest = APIUpdateCategoryRequest(name: updateName, icon: "heart.fill", color: nil, is_hidden: nil)
        let updated: APICustomCategory = try await AppAPIClient.shared.put(.raw("/categories/\(created.id)"), body: updateRequest)

        #expect(updated.name == updateName)
        #expect(updated.icon == "heart.fill")
    }

    @Test("Update category can hide and unhide")
    mutating func testCategoryUpdateHideUnhide() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let createRequest = APICreateCategoryRequest(
            id: nil,
            name: "Hide Test \(UUID().uuidString.prefix(8))",
            icon: "eye.fill",
            color: "#45B7D1",
            isHidden: nil,
            isPredefined: nil,
            predefinedKey: nil
        )
        let created: APICustomCategory = try await AppAPIClient.shared.post(.raw("/categories"), body: createRequest)

        await delay(200)

        // Hide it
        let hideRequest = APIUpdateCategoryRequest(name: nil, icon: nil, color: nil, is_hidden: true)
        let hidden: APICustomCategory = try await AppAPIClient.shared.put(.raw("/categories/\(created.id)"), body: hideRequest)
        #expect(hidden.isHidden == true)

        await delay(200)

        // Unhide it
        let unhideRequest = APIUpdateCategoryRequest(name: nil, icon: nil, color: nil, is_hidden: false)
        let restored: APICustomCategory = try await AppAPIClient.shared.put(.raw("/categories/\(created.id)"), body: unhideRequest)
        #expect(restored.isHidden == false)
    }

    @Test("Delete custom category removes it from list")
    mutating func testCategoryDelete() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let createRequest = APICreateCategoryRequest(
            id: nil,
            name: "Delete Me \(UUID().uuidString.prefix(8))",
            icon: "trash.fill",
            color: "#FF5733",
            isHidden: nil,
            isPredefined: nil,
            predefinedKey: nil
        )
        let created: APICustomCategory = try await AppAPIClient.shared.post(.raw("/categories"), body: createRequest)

        await delay(200)

        let _: APIMessageResponse = try await AppAPIClient.shared.deleteMessage(.raw("/categories/\(created.id)"))

        await delay(200)

        let categories: APIListResponse<APICustomCategory> = try await AppAPIClient.shared.get(.raw("/categories"))
        #expect(!categories.data.contains(where: { $0.id == created.id }))
    }

    @Test("Delete predefined override resets to default (row removed)")
    mutating func testCategoryDeletePredefinedOverride() async throws {
        try await ensureAuthenticated()
        await delay(200)

        // First create a predefined override
        struct APIPredefinedOverrideRequest: Codable {
            let id: UUID?
            let name: String
            let icon: String
            let color: String
            let predefined_key: String
        }

        let request = APIPredefinedOverrideRequest(
            id: nil,
            name: "Custom Transport Name",
            icon: "car.circle.fill",
            color: "#4ECDC4",
            predefined_key: "transport"
        )
        let created: APICustomCategory = try await AppAPIClient.shared.post(.raw("/categories"), body: request)

        await delay(200)

        // Delete the override → should reset to default (row removed server-side)
        let _: APIMessageResponse = try await AppAPIClient.shared.deleteMessage(.raw("/categories/\(created.id)"))

        await delay(200)

        // Override row should be gone
        let categories: APIListResponse<APICustomCategory> = try await AppAPIClient.shared.get(.raw("/categories"))
        #expect(!categories.data.contains(where: { $0.id == created.id }))
    }

    // MARK: - Budget Tests

    @Test("Create budget returns 200/201")
    mutating func testBudgetCreate() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let request = APICreateBudgetRequest(id: nil, year: 2026, month: 12, limit: 5000.00)
        let response: APIMonthlyBudget = try await AppAPIClient.shared.post(.raw("/budgets"), body: request)

        #expect(compareAmount(response.limit, request.limit))
    }

    @Test("List budgets returns data array")
    mutating func testBudgetList() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let response: APIListResponse<APIMonthlyBudget> = try await AppAPIClient.shared.get(.raw("/budgets"))

        #expect(!response.data.isEmpty)
    }

    @Test("Update budget modifies limit")
    mutating func testBudgetUpdate() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let createRequest = APICreateBudgetRequest(id: nil, year: 2026, month: 9, limit: 1000.00)
        let created: APIMonthlyBudget = try await AppAPIClient.shared.post(.raw("/budgets"), body: createRequest)

        await delay(200)

        let updateRequest = APIUpdateBudgetRequest(year: nil, month: nil, limit: 1500.00)
        let updated: APIMonthlyBudget = try await AppAPIClient.shared.put(.raw("/budgets/\(created.id)"), body: updateRequest)

        #expect(compareAmount(updated.limit, 1500))
    }

    @Test("Delete budget removes it")
    mutating func testBudgetDelete() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let request = APICreateBudgetRequest(id: nil, year: 2025, month: 12, limit: 999.00)
        let created: APIMonthlyBudget = try await AppAPIClient.shared.post(.raw("/budgets"), body: request)

        await delay(200)

        try await AppAPIClient.shared.delete(.raw("/budgets/\(created.id)"))
    }

    // MARK: - Recurring Transaction Tests

    @Test("Create monthly recurring transaction")
    mutating func testRecurringTransactionCreateMonthly() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let startDate = ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z")!
        let request = APICreateRecurringTransactionRequest(
            id: nil,
            name: "Netflix \(UUID().uuidString.prefix(4))",
            amount: 15.99,
            category: "Entertainment",
            frequency: "monthly",
            dayOfMonth: 15,
            daysOfWeek: nil,
            startDate: startDate,
            endDate: nil,
            isActive: true,
            notes: nil,
            type: "expense"
        )

        let response: APIRecurringTransaction = try await AppAPIClient.shared.post(.raw("/recurring-transactions"), body: request)

        #expect(response.name == request.name)
        #expect(compareAmount(response.amount, request.amount))
    }

    @Test("Create weekly recurring transaction")
    mutating func testRecurringTransactionCreateWeekly() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let startDate = ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z")!
        let request = APICreateRecurringTransactionRequest(
            id: nil,
            name: "Gym \(UUID().uuidString.prefix(4))",
            amount: 50.00,
            category: "Health & Medical",
            frequency: "weekly",
            dayOfMonth: nil,
            daysOfWeek: [1, 3, 5],
            startDate: startDate,
            endDate: nil,
            isActive: true,
            notes: nil,
            type: "expense"
        )

        let response: APIRecurringTransaction = try await AppAPIClient.shared.post(.raw("/recurring-transactions"), body: request)

        #expect(response.frequency == "weekly")
        #expect(response.daysOfWeek == [1, 3, 5])
        #expect(compareAmount(response.amount, request.amount))
    }

    @Test("List recurring transactions")
    mutating func testRecurringTransactionList() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let response: APIListResponse<APIRecurringTransaction> = try await AppAPIClient.shared.get(.raw("/recurring-transactions"))

        #expect(!response.data.isEmpty)
    }

    @Test("Get recurring transaction by id")
    mutating func testRecurringTransactionGetById() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let startDate = ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z")!
        let createRequest = APICreateRecurringTransactionRequest(
            id: nil,
            name: "Get Test \(UUID().uuidString.prefix(4))",
            amount: 5.00,
            category: "Other",
            frequency: "monthly",
            dayOfMonth: 20,
            daysOfWeek: nil,
            startDate: startDate,
            endDate: nil,
            isActive: true,
            notes: nil,
            type: "expense"
        )
        let created: APIRecurringTransaction = try await AppAPIClient.shared.post(.raw("/recurring-transactions"), body: createRequest)

        await delay(200)

        let response: APIRecurringTransaction = try await AppAPIClient.shared.get(.raw("/recurring-transactions/\(created.id)"))

        #expect(response.id == created.id)
    }

    @Test("Update recurring transaction")
    mutating func testRecurringTransactionUpdate() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let startDate = ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z")!
        let createRequest = APICreateRecurringTransactionRequest(
            id: nil,
            name: "Update Test \(UUID().uuidString.prefix(4))",
            amount: 10.00,
            category: "Entertainment",
            frequency: "monthly",
            dayOfMonth: 5,
            daysOfWeek: nil,
            startDate: startDate,
            endDate: nil,
            isActive: true,
            notes: nil,
            type: "expense"
        )
        let created: APIRecurringTransaction = try await AppAPIClient.shared.post(.raw("/recurring-transactions"), body: createRequest)

        await delay(200)

        let updateRequest = APIUpdateRecurringTransactionRequest(
            name: nil, amount: 12.00, category: nil, frequency: nil,
            dayOfMonth: nil, daysOfWeek: nil, startDate: nil, endDate: nil,
            isActive: false, notes: nil,
            type: "expense"
        )
        let updated: APIRecurringTransaction = try await AppAPIClient.shared.put(.raw("/recurring-transactions/\(created.id)"), body: updateRequest)

        #expect(compareAmount(updated.amount, 12))
        #expect(updated.isActive == false)
    }

    @Test("Delete recurring transaction")
    mutating func testRecurringTransactionDelete() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let startDate = ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z")!
        let createRequest = APICreateRecurringTransactionRequest(
            id: nil,
            name: "Delete Test \(UUID().uuidString.prefix(4))",
            amount: 8.00,
            category: "Other",
            frequency: "monthly",
            dayOfMonth: 10,
            daysOfWeek: nil,
            startDate: startDate,
            endDate: nil,
            isActive: true,
            notes: nil,
            type: "expense"
        )
        let created: APIRecurringTransaction = try await AppAPIClient.shared.post(.raw("/recurring-transactions"), body: createRequest)

        await delay(200)

        try await AppAPIClient.shared.delete(.raw("/recurring-transactions/\(created.id)"))
    }

    // MARK: - Transaction Tests

    @Test("Create expense transaction")
    mutating func testTransactionCreateExpense() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let request = APICreateTransactionRequest(
            id: nil,
            type: "expense",
            amount: 25.50,
            category: "Food & Dining",
            date: Date(),
            time: nil,
            description: "Test lunch",
            notes: nil,
            recurringExpenseId: nil
        )

        let response: APITransaction = try await AppAPIClient.shared.post(.raw("/transactions"), body: request)

        #expect(compareAmount(response.amount, request.amount))
        #expect(response.category == request.category)
        #expect(response.type == "expense")
        #expect(response.groupTransactionId == nil)
    }

    @Test("Create income transaction")
    mutating func testTransactionCreateIncome() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let request = APICreateTransactionRequest(
            id: nil,
            type: "income",
            amount: 5000.00,
            category: "Work & Professional",
            date: Date(),
            time: nil,
            description: "Monthly salary",
            notes: nil,
            recurringExpenseId: nil
        )

        let response: APITransaction = try await AppAPIClient.shared.post(.raw("/transactions"), body: request)

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
            amount: 45.00,
            category: "Shopping",
            date: Date(),
            time: ISO8601DateFormatter().date(from: "2026-03-22T14:30:00Z"),
            description: "Groceries",
            notes: "Weekly shopping",
            recurringExpenseId: nil
        )

        let response: APITransaction = try await AppAPIClient.shared.post(.raw("/transactions"), body: request)

        #expect(compareAmount(response.amount, request.amount))
        #expect(response.description == request.description)
        #expect(response.notes == request.notes)
    }

    @Test("List transactions returns paginated response")
    mutating func testTransactionListPaginated() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let response: APIPaginatedResponse<APITransaction> = try await AppAPIClient.shared.get(.raw("/transactions"))

        #expect(!response.data.isEmpty)
    }

    @Test("List transactions filtered by type=expense")
    mutating func testTransactionListFilteredByExpense() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let (response, _): BaseAPI.APIResponse<APIPaginatedResponse<APITransaction>> = try await AppAPIClient.shared.client
            .request(.raw("/transactions?type=expense"))
            .response()

        #expect(response.data.allSatisfy { $0.type == "expense" })
    }

    @Test("List transactions filtered by type=income")
    mutating func testTransactionListFilteredByIncome() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let (response, _): BaseAPI.APIResponse<APIPaginatedResponse<APITransaction>> = try await AppAPIClient.shared.client
            .request(.raw("/transactions?type=income"))
            .response()

        #expect(response.data.allSatisfy { $0.type == "income" })
    }

    @Test("Get transaction by id")
    mutating func testTransactionGetById() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let createRequest = APICreateTransactionRequest(
            id: nil,
            type: "expense",
            amount: 100.00,
            category: "Transport",
            date: Date(),
            time: nil,
            description: "Taxi",
            notes: nil,
            recurringExpenseId: nil
        )
        let created: APITransaction = try await AppAPIClient.shared.post(.raw("/transactions"), body: createRequest)

        await delay(200)

        let response: APITransaction = try await AppAPIClient.shared.get(.raw("/transactions/\(created.id)"))

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
            amount: 50.00,
            category: "Food & Dining",
            date: Date(),
            time: nil,
            description: "Before update",
            notes: nil,
            recurringExpenseId: nil
        )
        let created: APITransaction = try await AppAPIClient.shared.post(.raw("/transactions"), body: createRequest)

        await delay(200)

        let updateRequest = APIUpdateTransactionRequest(
            type: nil,
            amount: 55.00,
            category: nil,
            date: nil,
            time: nil,
            description: "After update",
            notes: nil
        )
        let updated: APITransaction = try await AppAPIClient.shared.patch(.raw("/transactions/\(created.id)"), body: updateRequest)

        #expect(compareAmount(updated.amount, 55))
        #expect(updated.description == "After update")
    }

    @Test("Delete transaction soft deletes")
    mutating func testTransactionDelete() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let createRequest = APICreateTransactionRequest(
            id: nil,
            type: "expense",
            amount: 75.00,
            category: "Shopping",
            date: Date(),
            time: nil,
            description: "To be deleted",
            notes: nil,
            recurringExpenseId: nil
        )
        let created: APITransaction = try await AppAPIClient.shared.post(.raw("/transactions"), body: createRequest)

        await delay(200)

        try await AppAPIClient.shared.delete(.raw("/transactions/\(created.id)"))

        await delay(200)

        let response: APITransaction = try await AppAPIClient.shared.get(.raw("/transactions/\(created.id)"))
        #expect(response.isDeleted == true)
    }

    // MARK: - Group Transaction Tests

    @Test("Create group and add group transaction")
    mutating func testGroupTransactionCreate() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let groupRequest = APICreateGroupRequest(name: "Test Group \(UUID().uuidString.prefix(4))")
        let group: APIGroup = try await AppAPIClient.shared.post(.raw("/groups"), body: groupRequest)

        await delay(200)

        let membersResponse: APIListResponse<APIGroupMember> = try await AppAPIClient.shared.get(.raw("/groups/\(group.id)/members"))
        guard let member = membersResponse.data.first else {
            Issue.record("Group has no members")
            return
        }

        let txRequest = APICreateGroupTransactionRequest(
            paidByUserId: member.id,
            totalAmount: 90.00,
            category: "Food & Dining",
            date: Date(),
            description: "Group dinner",
            notes: nil,
            splits: [
                APIGroupTransactionSplitInput(userId: member.id, amount: 90.00)
            ]
        )

        let response: APIGroupTransaction = try await AppAPIClient.shared.post(
            .raw("/groups/\(group.id)/transactions"),
            body: txRequest
        )

        #expect(compareAmount(response.totalAmount, 90.00))
        #expect(response.category == "Food & Dining")
        #expect(response.paidByUserId == member.id)
        #expect(!response.splits.isEmpty)
    }

    @Test("List group transactions")
    mutating func testGroupTransactionList() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let groupRequest = APICreateGroupRequest(name: "List Test \(UUID().uuidString.prefix(4))")
        let group: APIGroup = try await AppAPIClient.shared.post(.raw("/groups"), body: groupRequest)

        await delay(200)

        let membersResponse: APIListResponse<APIGroupMember> = try await AppAPIClient.shared.get(.raw("/groups/\(group.id)/members"))
        guard let member = membersResponse.data.first else {
            Issue.record("Group has no members")
            return
        }

        let txRequest = APICreateGroupTransactionRequest(
            paidByUserId: member.id,
            totalAmount: 30.00,
            category: "Transport",
            date: Date(),
            description: "Cab ride",
            notes: nil,
            splits: [
                APIGroupTransactionSplitInput(userId: member.id, amount: 30.00)
            ]
        )
        let _: APIGroupTransaction = try await AppAPIClient.shared.post(.raw("/groups/\(group.id)/transactions"), body: txRequest)

        await delay(200)

        struct GroupTransactionsResponse: Codable { let data: [APIGroupTransaction] }
        let response: GroupTransactionsResponse = try await AppAPIClient.shared.get(.raw("/groups/\(group.id)/transactions"))

        #expect(!response.data.isEmpty)
    }

    // MARK: - Dashboard Tests

    @Test("Dashboard monthly returns overview")
    mutating func testDashboardMonthly() async throws {
        try await ensureAuthenticated()
        await delay(200)

        let month = Calendar.current.component(.month, from: Date())
        let year = Calendar.current.component(.year, from: Date())

        let (response, _): BaseAPI.APIResponse<APIMonthlyDashboardResponse> = try await AppAPIClient.shared.client
            .request(.raw("/dashboard/monthly?month=\(month)&year=\(year)"))
            .response()

        #expect(response.totalTransactions != nil)
    }

    // MARK: - Cleanup

    @Test("Cleanup: delete test user")
    func testCleanupDeleteUser() async throws {
        guard !Self.authToken.isEmpty else { return }
        await delay(200)
        try await AppAPIClient.shared.delete(.raw("/me"))
    }
}

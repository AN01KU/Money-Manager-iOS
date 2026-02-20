import Foundation
import Combine

@MainActor
final class MockAPIService: ObservableObject {
    static let shared = MockAPIService()
    
    @Published var currentUser: APIUser?
    @Published var isAuthenticated = false
    
    // MARK: - API Delays (in milliseconds) - Adjust these per endpoint
    private let delays: [String: UInt64] = [
        "auth": 800,           // Auth endpoints (login/signup)
        "health": 200,         // Health check
        "groups": 500,         // Group operations
        "expenses": 600,       // Expense operations
        "balances": 400,       // Balance calculations
        "settlements": 700,    // Settlement operations
        "budget": 450,         // Budget operations
        "categories": 350,     // Category operations
        "personal-expenses": 550,  // Personal expense operations
        "dashboard": 900,      // Dashboard (heavier calculation)
    ]
    
    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()
    
    private func isoString(from date: Date = Date()) -> String {
        isoFormatter.string(from: date)
    }
    
    private init() {
        isAuthenticated = KeychainService.shared.isLoggedIn
        if isAuthenticated {
            currentUser = APIUser(
                id: UUID(),
                email: MockData.currentUser.email,
                createdAt: isoString()
            )
        }
    }
    
    // MARK: - Private Helper
    private func getDelay(for endpoint: String) -> UInt64 {
        let parts = endpoint.split(separator: "/")
        let key = String(parts.first ?? "")
        return delays[key] ?? 500
    }
    
    private func simulateDelay(for endpoint: String) async {
        let delayMs = getDelay(for: endpoint)
        let delayNs = delayMs * 1_000_000
        try? await Task.sleep(nanoseconds: delayNs)
    }
    
    // MARK: - Auth
    
    func signup(email: String, password: String) async throws -> AuthResponse {
        await simulateDelay(for: "auth/signup")
        
        let user = APIUser(id: UUID(), email: email, createdAt: isoString())
        let token = UUID().uuidString
        
        KeychainService.shared.saveToken(token)
        currentUser = user
        isAuthenticated = true
        
        return AuthResponse(token: token, user: user)
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        await simulateDelay(for: "auth/login")
        
        let user = APIUser(id: UUID(), email: email, createdAt: isoString())
        let token = UUID().uuidString
        
        KeychainService.shared.saveToken(token)
        currentUser = user
        isAuthenticated = true
        
        return AuthResponse(token: token, user: user)
    }
    
    func logout() {
        KeychainService.shared.deleteToken()
        currentUser = nil
        isAuthenticated = false
    }
    
    func healthCheck() async throws -> HealthResponse {
        await simulateDelay(for: "health")
        return HealthResponse(status: "ok", database: "connected")
    }
    
    // MARK: - Groups
    
    func createGroup(name: String) async throws -> SplitGroup {
        await simulateDelay(for: "groups")
        return MockData.groups.first ?? SplitGroup(
            id: UUID(),
            name: name,
            createdBy: currentUser?.id ?? UUID(),
            createdAt: isoString()
        )
    }
    
    func addMember(groupId: UUID, userEmail: String) async throws -> AddMemberResponse {
        await simulateDelay(for: "groups/add-member")
        return AddMemberResponse(message: "Member added successfully")
    }
    
    // MARK: - Expenses
    
    func createExpense(_ request: CreateSharedExpenseRequest) async throws -> SharedExpense {
        await simulateDelay(for: "expenses")
        return SharedExpense(
            id: UUID(),
            groupId: request.groupId,
            description: request.description,
            category: request.category,
            totalAmount: request.totalAmount,
            paidBy: currentUser?.id ?? UUID(),
            createdAt: isoString(),
            splits: request.splits
        )
    }
    
    func getGroupExpenses(groupId: UUID, limit: Int = 50, offset: Int = 0) async throws -> [SharedExpense] {
        await simulateDelay(for: "groups/expenses")
        return MockData.expenses[groupId] ?? []
    }
    
    // MARK: - Balances
    
    func getBalances(groupId: UUID) async throws -> [UserBalance] {
        await simulateDelay(for: "balances")
        return MockData.balances[groupId] ?? []
    }
    
    // MARK: - Settlements
    
    func createSettlement(_ request: CreateSettlementRequest) async throws -> Settlement {
        await simulateDelay(for: "settlements")
        return Settlement(
            id: UUID(),
            groupId: request.groupId,
            fromUser: request.fromUser,
            toUser: request.toUser,
            amount: request.amount,
            createdAt: isoString()
        )
    }
    
    // MARK: - Budget
    
    func setBudget(amount: Double, month: Int, year: Int) async throws -> BudgetResponse {
        await simulateDelay(for: "budget")
        let now = isoString()
        return BudgetResponse(
            id: UUID(),
            userId: currentUser?.id ?? UUID(),
            amount: String(amount),
            month: month,
            year: year,
            createdAt: now,
            updatedAt: now
        )
    }
    
    func getBudget(month: Int? = nil, year: Int? = nil) async throws -> BudgetResponse {
        await simulateDelay(for: "budget")
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.month, .year], from: now)
        let nowStr = isoString()
        
        return BudgetResponse(
            id: UUID(),
            userId: currentUser?.id ?? UUID(),
            amount: "5000",
            month: month ?? components.month ?? 1,
            year: year ?? components.year ?? 2025,
            createdAt: nowStr,
            updatedAt: nowStr
        )
    }
    
    func getAllBudgets() async throws -> [BudgetResponse] {
        await simulateDelay(for: "budget")
        let nowStr = isoString()
        return [
            BudgetResponse(
                id: UUID(),
                userId: currentUser?.id ?? UUID(),
                amount: "5000",
                month: 1,
                year: 2025,
                createdAt: nowStr,
                updatedAt: nowStr
            )
        ]
    }
    
    // MARK: - Categories
    
    func createCategory(name: String, color: String, icon: String) async throws -> CategoryResponse {
        await simulateDelay(for: "categories")
        return CategoryResponse(
            id: UUID(),
            userId: currentUser?.id ?? UUID(),
            name: name,
            color: color,
            icon: icon,
            createdAt: isoString()
        )
    }
    
    func getCategories() async throws -> [CategoryResponse] {
        await simulateDelay(for: "categories")
        let userId = currentUser?.id ?? UUID()
        let now = isoString()
        return [
            CategoryResponse(id: UUID(), userId: userId, name: "Food", color: "#FF6B6B", icon: "🍔", createdAt: now),
            CategoryResponse(id: UUID(), userId: userId, name: "Transport", color: "#4ECDC4", icon: "🚗", createdAt: now),
            CategoryResponse(id: UUID(), userId: userId, name: "Entertainment", color: "#95E1D3", icon: "🎬", createdAt: now),
            CategoryResponse(id: UUID(), userId: userId, name: "Shopping", color: "#F38181", icon: "🛍️", createdAt: now),
        ]
    }
    
    func updateCategory(id: UUID, name: String?, color: String?, icon: String?) async throws -> CategoryResponse {
        await simulateDelay(for: "categories/update")
        return CategoryResponse(
            id: id,
            userId: currentUser?.id ?? UUID(),
            name: name ?? "Category",
            color: color ?? "#000000",
            icon: icon ?? "📌",
            createdAt: isoString()
        )
    }
    
    func deleteCategory(id: UUID) async throws -> MessageResponse {
        await simulateDelay(for: "categories/delete")
        return MessageResponse(message: "Category deleted successfully")
    }
    
    // MARK: - Personal Expenses
    
    func createPersonalExpense(_ request: CreatePersonalExpenseRequest) async throws -> PersonalExpenseResponse {
        await simulateDelay(for: "personal-expenses")
        let now = isoString()
        return PersonalExpenseResponse(
            id: UUID(),
            userId: currentUser?.id ?? UUID(),
            categoryId: request.categoryId,
            amount: request.amount,
            description: request.description,
            notes: request.notes,
            expenseDate: request.expenseDate,
            createdAt: now,
            updatedAt: now
        )
    }
    
    func getPersonalExpenses(limit: Int = 50, offset: Int = 0, categoryId: UUID? = nil, startDate: String? = nil, endDate: String? = nil) async throws -> PaginatedPersonalExpensesResponse {
        await simulateDelay(for: "personal-expenses")
        return PaginatedPersonalExpensesResponse(
            expenses: [],
            pagination: Pagination(limit: limit, offset: offset, total: 0)
        )
    }
    
    func getPersonalExpense(id: UUID) async throws -> PersonalExpenseResponse {
        await simulateDelay(for: "personal-expenses/get")
        let now = isoString()
        return PersonalExpenseResponse(
            id: id,
            userId: currentUser?.id ?? UUID(),
            categoryId: UUID(),
            amount: "100.00",
            description: "Sample expense",
            notes: nil,
            expenseDate: now,
            createdAt: now,
            updatedAt: now
        )
    }
    
    func updatePersonalExpense(id: UUID, amount: Double?, description: String?, notes: String?) async throws -> PersonalExpenseResponse {
        await simulateDelay(for: "personal-expenses/update")
        let now = isoString()
        return PersonalExpenseResponse(
            id: id,
            userId: currentUser?.id ?? UUID(),
            categoryId: UUID(),
            amount: amount.map { String($0) } ?? "0",
            description: description ?? "",
            notes: notes,
            expenseDate: now,
            createdAt: now,
            updatedAt: now
        )
    }
    
    func deletePersonalExpense(id: UUID) async throws -> MessageResponse {
        await simulateDelay(for: "personal-expenses/delete")
        return MessageResponse(message: "Expense deleted successfully")
    }
    
    // MARK: - Dashboard
    
    func getMonthlyDashboard(month: Int? = nil, year: Int? = nil) async throws -> DashboardResponse {
        await simulateDelay(for: "dashboard/monthly")
        
        let m = month ?? Calendar.current.component(.month, from: Date())
        let y = year ?? Calendar.current.component(.year, from: Date())
        
        return DashboardResponse(
            month: m,
            year: y,
            budget: "5000.00",
            totalSpent: "1500.50",
            remainingBudget: "3499.50",
            daysInMonth: 30,
            daysElapsed: 15,
            daysRemaining: 15,
            dailyAverageSpent: "100.03",
            projectedSpending: "3001.00",
            isOverBudget: false,
            expenseCount: 12,
            categoryBreakdown: [
                CategoryBreakdown(categoryId: UUID(), categoryName: "Food", totalAmount: "450.00", expenseCount: 5),
                CategoryBreakdown(categoryId: UUID(), categoryName: "Transport", totalAmount: "300.00", expenseCount: 3),
            ]
        )
    }
}

import Foundation
import Combine
import SwiftData

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case badRequest(String)
    case serverError(Int)
    case decodingError
    case networkError(Error)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .unauthorized:
            return "Session expired. Please log in again."
        case .badRequest(let message):
            return message
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .decodingError:
            return "Failed to process server response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout:
            return "Request timeout. Please check your connection."
        }
    }
}

@MainActor
final class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "http://192.168.1.50:8080"
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    @Published var currentUser: APIUser?
    @Published var isAuthenticated = false
    
    private var modelContext: ModelContext?
    
    private init() {
        isAuthenticated = KeychainService.shared.isLoggedIn
    }
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCachedUser()
        
        if isAuthenticated {
            Task {
                try? await syncUserData()
            }
        }
    }
    
    private func loadCachedUser() {
        guard isAuthenticated, let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<CachedUser>()
        if let cached = try? context.fetch(descriptor).first {
            currentUser = APIUser(id: cached.id, email: cached.email, username: cached.username, createdAt: cached.createdAt)
        }
    }
    
    private func cacheUser(_ user: APIUser) {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<CachedUser>()
        let existing = try? context.fetch(descriptor).first
        
        if let existing = existing {
            existing.email = user.email
            existing.username = user.username
            existing.createdAt = user.createdAt
        } else {
            let cached = CachedUser(id: user.id, email: user.email, username: user.username, createdAt: user.createdAt)
            context.insert(cached)
        }
        
        try? context.save()
    }
    
    private func clearCachedUser() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<CachedUser>()
        if let cached = try? context.fetch(descriptor).first {
            context.delete(cached)
            try? context.save()
        }
    }
    
    // MARK: - Auth
    
    func signup(email: String, password: String, username: String) async throws -> AuthResponse {
        let body = AuthRequest(email: email, password: password, username: username)
        let response: AuthResponse = try await post("/auth/signup", body: body, authenticated: false)
        KeychainService.shared.saveToken(response.token)
        currentUser = response.user
        cacheUser(response.user)
        isAuthenticated = true
        return response
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let body = AuthRequest(email: email, password: password, username: "")
        let response: AuthResponse = try await post("/auth/login", body: body, authenticated: false)
        KeychainService.shared.saveToken(response.token)
        currentUser = response.user
        cacheUser(response.user)
        isAuthenticated = true
        return response
    }
    
    func logout() {
        KeychainService.shared.deleteToken()
        currentUser = nil
        clearCachedUser()
        isAuthenticated = false
    }
    
    func syncUserData() async throws {
        guard let context = modelContext else { return }
        
        async let personalExpensesTask = getPersonalExpenses()
        async let budgetsTask = getAllBudgets()
        async let categoriesTask = getCategories()
        async let groupsTask = getGroups()
        
        let (personalExpensesResponse, budgets, categories, groups) = try await (personalExpensesTask, budgetsTask, categoriesTask, groupsTask)
        
        let dateFormatter = ISO8601DateFormatter()
        
        // Sync personal expenses
        for expense in personalExpensesResponse.expenses {
            let expenseDate = dateFormatter.date(from: expense.expenseDate) ?? Date()
            let expenseId = expense.id
            
            let descriptor = FetchDescriptor<Expense>(predicate: #Predicate<Expense> { item in
                item.id == expenseId
            })
            let existing = try? context.fetch(descriptor)
            if existing?.isEmpty ?? true {
                let newExpense = Expense(
                    amount: Double(expense.amount) ?? 0,
                    category: expense.category ?? "",
                    date: expenseDate,
                    expenseDescription: expense.description,
                    notes: expense.notes,
                    isRecurring: expense.isRecurring ?? false,
                    frequency: expense.frequency,
                    dayOfMonth: expense.dayOfMonth,
                    recurringEndDate: expense.recurringEndDate.flatMap { dateFormatter.date(from: $0) }
                )
                newExpense.id = expense.id
                context.insert(newExpense)
            }
        }
        
        // Sync budgets
        for budget in budgets {
            let budgetId = budget.id
            let descriptor = FetchDescriptor<MonthlyBudget>(predicate: #Predicate<MonthlyBudget> { item in
                item.id == budgetId
            })
            let existing = try? context.fetch(descriptor)
            if existing?.isEmpty ?? true {
                let newBudget = MonthlyBudget(
                    year: budget.year,
                    month: budget.month,
                    limit: Double(budget.amount) ?? 0
                )
                newBudget.id = budget.id
                context.insert(newBudget)
            }
        }
        
        // Sync categories
        for category in categories {
            let categoryId = category.id
            let descriptor = FetchDescriptor<CustomCategory>(predicate: #Predicate<CustomCategory> { item in
                item.id == categoryId
            })
            let existing = try? context.fetch(descriptor)
            if existing?.isEmpty ?? true {
                let newCategory = CustomCategory(
                    name: category.name,
                    icon: category.icon,
                    color: category.color
                )
                newCategory.id = category.id
                context.insert(newCategory)
            }
        }
        
        // Sync groups with members, expenses, balances
        for group in groups {
            let groupId = group.id
            let descriptor = FetchDescriptor<SplitGroupModel>(predicate: #Predicate<SplitGroupModel> { item in
                item.id == groupId
            })
            let existing = try? context.fetch(descriptor)
            
            if existing?.isEmpty ?? true {
                let newGroup = SplitGroupModel(
                    id: group.id,
                    name: group.name,
                    createdBy: group.createdBy,
                    createdAt: group.createdAt
                )
                context.insert(newGroup)
                
                // Sync members
                if let members = try? await getGroupMembers(groupId: group.id) {
                    for member in members {
                        let memberId = member.id
                        let memberDescriptor = FetchDescriptor<GroupMemberModel>(predicate: #Predicate<GroupMemberModel> { item in
                            item.id == memberId
                        })
                        let memberExists = try? context.fetch(memberDescriptor)
                        if memberExists?.isEmpty ?? true {
                            let newMember = GroupMemberModel(
                                id: member.id,
                                email: member.email,
                                username: member.username,
                                createdAt: member.createdAt
                            )
                            newMember.group = newGroup
                            context.insert(newMember)
                        }
                    }
                }
                
                // Sync group expenses
                if let expenses = try? await getGroupExpenses(groupId: group.id) {
                    for expense in expenses {
                        let expId = expense.id
                        let expDescriptor = FetchDescriptor<GroupExpenseModel>(predicate: #Predicate<GroupExpenseModel> { item in
                            item.id == expId
                        })
                        let expExists = try? context.fetch(expDescriptor)
                        if expExists?.isEmpty ?? true {
                            let newExpense = GroupExpenseModel(
                                id: expense.id,
                                description: expense.description,
                                category: expense.category,
                                totalAmount: Double(expense.totalAmount) ?? 0,
                                paidBy: expense.paidBy,
                                createdAt: expense.createdAt
                            )
                            newExpense.group = newGroup
                            context.insert(newExpense)
                        }
                    }
                }
                
                // Sync group balances
                if let balances = try? await getBalances(groupId: group.id) {
                    for balance in balances {
                        let balanceUserId = balance.userId
                        let balanceDescriptor = FetchDescriptor<GroupBalanceModel>(predicate: #Predicate<GroupBalanceModel> { item in
                            item.userId == balanceUserId
                        })
                        let balanceExists = try? context.fetch(balanceDescriptor)
                        if balanceExists?.isEmpty ?? true {
                            let newBalance = GroupBalanceModel(
                                userId: balance.userId,
                                amount: Double(balance.amount) ?? 0,
                                group: newGroup
                            )
                            context.insert(newBalance)
                        }
                    }
                }
            }
        }
        
        try context.save()
    }
    
    func healthCheck() async throws -> HealthResponse {
        return try await get("/health", authenticated: false)
    }
    
    // MARK: - Groups
    
    func getGroups() async throws -> [SplitGroup] {
        return try await get("/groups")
    }
    
    func createGroup(name: String) async throws -> SplitGroup {
        let body = CreateGroupRequest(name: name)
        return try await post("/groups", body: body)
    }
    
    func getGroupMembers(groupId: UUID) async throws -> [APIUser] {
        return try await get("/groups/\(groupId)/members")
    }
    
    func addMember(groupId: UUID, email: String) async throws -> AddMemberResponse {
        let body = AddMemberRequest(email: email)
        return try await post("/groups/\(groupId)/add-member", body: body)
    }
    
    // MARK: - Expenses
    
    func createExpense(_ request: CreateSharedExpenseRequest) async throws -> SharedExpense {
        return try await post("/expenses", body: request)
    }
    
    func getGroupExpenses(groupId: UUID, limit: Int = 50, offset: Int = 0) async throws -> [SharedExpense] {
        let response: PaginatedExpensesResponse = try await get("/groups/\(groupId)/expenses?limit=\(limit)&offset=\(offset)")
        return response.expenses
    }
    
    // MARK: - Balances
    
    func getBalances(groupId: UUID) async throws -> [UserBalance] {
        return try await get("/groups/\(groupId)/balances")
    }
    
    // MARK: - Settlements
    
    func createSettlement(_ request: CreateSettlementRequest) async throws -> Settlement {
        return try await post("/settlements", body: request)
    }
    
    // MARK: - Budget
    
    func setBudget(amount: Double, month: Int, year: Int) async throws -> BudgetResponse {
        let body = SetBudgetRequest(amount: String(amount), month: month, year: year)
        return try await post("/budget", body: body)
    }
    
    func getBudget(month: Int? = nil, year: Int? = nil) async throws -> BudgetResponse {
        var query = ""
        if let month = month, let year = year {
            query = "?month=\(month)&year=\(year)"
        }
        return try await get("/budget\(query)")
    }
    
    func getAllBudgets() async throws -> [BudgetResponse] {
        return try await get("/budgets")
    }
    
    // MARK: - Categories
    
    func createCategory(name: String, color: String, icon: String) async throws -> CategoryResponse {
        let body = CreateCategoryRequest(name: name, color: color, icon: icon)
        return try await post("/categories", body: body)
    }
    
    func getCategories() async throws -> [CategoryResponse] {
        return try await get("/categories")
    }
    
    func updateCategory(id: UUID, name: String?, color: String?, icon: String?) async throws -> CategoryResponse {
        let body = UpdateCategoryRequest(name: name, color: color, icon: icon)
        return try await put("/categories/\(id)", body: body)
    }
    
    func deleteCategory(id: UUID) async throws -> MessageResponse {
        return try await delete("/categories/\(id)")
    }
    
    // MARK: - Personal Expenses
    
    func createPersonalExpense(_ request: CreatePersonalExpenseRequest) async throws -> PersonalExpenseResponse {
        return try await post("/personal-expenses", body: request)
    }
    
    func getPersonalExpenses(limit: Int = 50, offset: Int = 0, category: String? = nil, startDate: String? = nil, endDate: String? = nil) async throws -> PaginatedPersonalExpensesResponse {
        var query = "?limit=\(limit)&offset=\(offset)"
        if let category = category {
            query += "&category=\(category)"
        }
        if let startDate = startDate {
            query += "&start_date=\(startDate)"
        }
        if let endDate = endDate {
            query += "&end_date=\(endDate)"
        }
        return try await get("/personal-expenses\(query)")
    }
    
    func getPersonalExpense(id: UUID) async throws -> PersonalExpenseResponse {
        return try await get("/personal-expenses/\(id)")
    }
    
    func updatePersonalExpense(id: UUID, amount: Double?, description: String?, notes: String?, isRecurring: Bool? = nil, frequency: String? = nil, dayOfMonth: Int? = nil, isActive: Bool? = nil) async throws -> PersonalExpenseResponse {
        let body = UpdatePersonalExpenseRequest(amount: amount.map { String($0) }, description: description, notes: notes, isRecurring: isRecurring, frequency: frequency, dayOfMonth: dayOfMonth, isActive: isActive)
        return try await put("/personal-expenses/\(id)", body: body)
    }
    
    func deletePersonalExpense(id: UUID) async throws -> MessageResponse {
        return try await delete("/personal-expenses/\(id)")
    }
    
    // MARK: - Dashboard
    
    func getMonthlyDashboard(month: Int? = nil, year: Int? = nil) async throws -> DashboardResponse {
        var query = ""
        if let month = month, let year = year {
            query = "?month=\(month)&year=\(year)"
        }
        return try await get("/dashboard/monthly\(query)")
    }
    
    // MARK: - Networking
    
    private func get<T: Decodable>(_ path: String, authenticated: Bool = true) async throws -> T {
        let request = try buildRequest(path: path, method: "GET", authenticated: authenticated)
        return try await perform(request)
    }
    
    private func post<T: Decodable, B: Encodable>(_ path: String, body: B, authenticated: Bool = true) async throws -> T {
        var request = try buildRequest(path: path, method: "POST", authenticated: authenticated)
        request.httpBody = try encoder.encode(body)
        return try await perform(request)
    }
    
    private func put<T: Decodable, B: Encodable>(_ path: String, body: B, authenticated: Bool = true) async throws -> T {
        var request = try buildRequest(path: path, method: "PUT", authenticated: authenticated)
        request.httpBody = try encoder.encode(body)
        return try await perform(request)
    }
    
    private func delete<T: Decodable>(_ path: String, authenticated: Bool = true) async throws -> T {
        let request = try buildRequest(path: path, method: "DELETE", authenticated: authenticated)
        return try await perform(request)
    }
    
    private func buildRequest(path: String, method: String, authenticated: Bool) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if authenticated {
            guard let token = KeychainService.shared.getToken() else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            ErrorHandler.shared.logError(error, context: "URLSession")
            if error.code == .timedOut {
                throw APIError.timeout
            }
            throw APIError.networkError(error)
        } catch {
            ErrorHandler.shared.logError(error, context: "URLSession")
            throw APIError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError(0)
        }
        
        switch httpResponse.statusCode {
        case 200...201:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                ErrorHandler.shared.logError(error, context: "Decoding")
                throw APIError.decodingError
            }
        case 401:
            logout()
            throw APIError.unauthorized
        case 400...499:
            if let errorBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorBody["error"] as? String {
                throw APIError.badRequest(message)
            }
            throw APIError.badRequest("Request failed")
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}

import Foundation
import Combine

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case badRequest(String)
    case serverError(Int)
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .unauthorized:
            return "Session expired. Please log in again."
        case .badRequest(let message):
            return message
        case .serverError(let code):
            return "Server error (\(code))"
        case .decodingError:
            return "Failed to process server response"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

@MainActor
final class APIService: ObservableObject {
    static let shared = APIService()
    
    // TODO: Update this to your actual backend URL
    private let baseURL = "http://localhost:8080"
    
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
    
    private init() {
        isAuthenticated = KeychainService.shared.isLoggedIn
    }
    
    // MARK: - Auth
    
    func signup(email: String, password: String) async throws -> AuthResponse {
        let body = AuthRequest(email: email, password: password)
        let response: AuthResponse = try await post("/auth/signup", body: body, authenticated: false)
        KeychainService.shared.saveToken(response.token)
        currentUser = response.user
        isAuthenticated = true
        return response
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let body = AuthRequest(email: email, password: password)
        let response: AuthResponse = try await post("/auth/login", body: body, authenticated: false)
        KeychainService.shared.saveToken(response.token)
        currentUser = response.user
        isAuthenticated = true
        return response
    }
    
    func logout() {
        KeychainService.shared.deleteToken()
        currentUser = nil
        isAuthenticated = false
    }
    
    func healthCheck() async throws -> HealthResponse {
        return try await get("/health", authenticated: false)
    }
    
    // MARK: - Groups
    
    func createGroup(name: String) async throws -> SplitGroup {
        let body = CreateGroupRequest(name: name)
        return try await post("/groups", body: body)
    }
    
    func addMember(groupId: UUID, userId: UUID) async throws -> AddMemberResponse {
        let body = AddMemberRequest(userId: userId)
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
    
    private func buildRequest(path: String, method: String, authenticated: Bool) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
        } catch {
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

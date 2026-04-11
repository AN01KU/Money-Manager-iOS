//
//  APIClient.swift
//  Money Manager
//

import Foundation

extension Notification.Name {
    static let authSessionExpired = Notification.Name("authSessionExpired")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let syncSessionOrphaned = Notification.Name("syncSessionOrphaned")
}

final class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let baseURL: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private var _testToken: String?
    private var _testSyncSessionID: UUID?
    private var _testURLSession: URLSession?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.API.defaultTimeout
        config.timeoutIntervalForResource = AppConstants.API.defaultTimeout
        self.session = URLSession(configuration: config)
        
        self.baseURL = "https://moneymanager.ankushganesh.cloud"
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let ms = try container.decode(Int64.self)
            return Date(timeIntervalSince1970: Double(ms) / 1000.0)
        }
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(Int64(date.timeIntervalSince1970 * 1000))
        }
    }
    
    #if DEBUG
    func setTestToken(_ token: String?) {
        _testToken = token
    }

    func clearTestToken() {
        _testToken = nil
    }

    func setTestSyncSessionID(_ id: UUID?) {
        _testSyncSessionID = id
    }

    /// Returns a fresh APIClient using the given URLSession — for unit tests only.
    static func makeForTesting(session testSession: URLSession) -> APIClient {
        let client = APIClient()
        client._testURLSession = testSession
        return client
    }
    #endif
    
    static let apiEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(Int64(date.timeIntervalSince1970 * 1000))
        }
        return encoder
    }()
    
    func get<T: Decodable>(_ endpoint: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        let request = try buildRequest(endpoint: endpoint, method: "GET", queryItems: queryItems)
        return try await perform(request)
    }
    
    func post<T: Decodable, U: Encodable>(_ endpoint: String, body: U) async throws -> T {
        var request = try buildRequest(endpoint: endpoint, method: "POST")
        request.httpBody = try encoder.encode(body)
        return try await perform(request)
    }
    
    func put<T: Decodable, U: Encodable>(_ endpoint: String, body: U) async throws -> T {
        var request = try buildRequest(endpoint: endpoint, method: "PUT")
        request.httpBody = try encoder.encode(body)
        return try await perform(request)
    }
    
    func post<T: Decodable>(_ endpoint: String, rawBody: Data) async throws -> T {
        var request = try buildRequest(endpoint: endpoint, method: "POST")
        request.httpBody = rawBody
        return try await perform(request)
    }
    
    func put<T: Decodable>(_ endpoint: String, rawBody: Data) async throws -> T {
        var request = try buildRequest(endpoint: endpoint, method: "PUT")
        request.httpBody = rawBody
        return try await perform(request)
    }

    func patch<T: Decodable, U: Encodable>(_ endpoint: String, body: U) async throws -> T {
        var request = try buildRequest(endpoint: endpoint, method: "PATCH")
        request.httpBody = try encoder.encode(body)
        return try await perform(request)
    }

    func patch<T: Decodable>(_ endpoint: String, rawBody: Data) async throws -> T {
        var request = try buildRequest(endpoint: endpoint, method: "PATCH")
        request.httpBody = rawBody
        return try await perform(request)
    }
    
    func delete(_ endpoint: String) async throws {
        let request = try buildRequest(endpoint: endpoint, method: "DELETE")
        let _: EmptyResponse = try await perform(request)
    }
    
    func deleteMessage(_ endpoint: String) async throws -> APIMessageResponse {
        let request = try buildRequest(endpoint: endpoint, method: "DELETE")
        return try await perform(request)
    }
    
    func ping() async -> Bool {
        do {
            let _: HealthResponse = try await get("/health")
            return true
        } catch {
            return false
        }
    }
    
    func buildRequest(
        endpoint: String,
        method: String,
        queryItems: [URLQueryItem]? = nil
    ) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        if let queryItems = queryItems {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let isAuthEndpoint = endpoint.hasPrefix("/auth/")
        if !isAuthEndpoint, let token = _testToken ?? SessionStore.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let writeMethods: Set<String> = ["POST", "PUT", "PATCH", "DELETE"]
        if writeMethods.contains(method),
           let syncSessionID = _testSyncSessionID ?? SessionStore.shared.getSyncSessionID() {
            request.setValue(syncSessionID.uuidString, forHTTPHeaderField: "X-Sync-Session-ID")
            request.setValue("1", forHTTPHeaderField: "X-Sync-Version")
        }

        return request
    }
    
    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let activeSession = _testURLSession ?? session
            let (data, response) = try await activeSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                throw APIError(from: httpResponse, data: data)
            }
            
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                Self.logDecodingError(error, type: T.self, endpoint: request.url?.path ?? "unknown", data: data)
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    #if DEBUG
    private static func logDecodingError<T>(_ error: Error, type: T.Type, endpoint: String, data: Data) {
        let typeName = String(describing: T.self)
        let preview = String(data: data.prefix(1024), encoding: .utf8) ?? "<binary>"

        switch error {
        case let error as DecodingError:
            switch error {
            case .typeMismatch(let expected, let context):
                AppLogger.network.error("Decoding \(typeName) from \(endpoint): type mismatch — expected \(String(describing: expected)) at \(context.codingPath.map(\.stringValue).joined(separator: ".")) — \(context.debugDescription)")
            case .valueNotFound(let expected, let context):
                AppLogger.network.error("Decoding \(typeName) from \(endpoint): missing value — expected \(String(describing: expected)) at \(context.codingPath.map(\.stringValue).joined(separator: ".")) — \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                AppLogger.network.error("Decoding \(typeName) from \(endpoint): missing key '\(key.stringValue)' at \(context.codingPath.map(\.stringValue).joined(separator: ".")) — \(context.debugDescription)")
            case .dataCorrupted(let context):
                AppLogger.network.error("Decoding \(typeName) from \(endpoint): data corrupted at \(context.codingPath.map(\.stringValue).joined(separator: ".")) — \(context.debugDescription)")
            @unknown default:
                AppLogger.network.error("Decoding \(typeName) from \(endpoint): \(error.localizedDescription)")
            }
        default:
            AppLogger.network.error("Decoding \(typeName) from \(endpoint): \(error.localizedDescription)")
        }

        AppLogger.network.debug("Response body preview for \(endpoint): \(preview)")
    }
    #else
    private static func logDecodingError<T>(_ error: Error, type: T.Type, endpoint: String, data: Data) {
        let typeName = String(describing: T.self)
        AppLogger.network.error("Decoding \(typeName) from \(endpoint) failed: \(error.localizedDescription)")
    }
    #endif
}

/// Decodes successfully regardless of the response body shape.
/// Used by the change queue replay where we only care that the request succeeded (2xx),
/// not the response payload — avoids decode failures on endpoints that return a body (e.g. POST /categories).
struct EmptyResponse: Decodable {
    init() {}
    init(from decoder: Decoder) throws {}
}

private struct HealthResponse: Decodable {
    let status: String
}

extension ISO8601DateFormatter {
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

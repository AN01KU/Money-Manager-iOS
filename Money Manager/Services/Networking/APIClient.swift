//
//  APIClient.swift
//  Money Manager
//

import Foundation

extension Notification.Name {
    static let authSessionExpired = Notification.Name("authSessionExpired")
    static let userDidLogout = Notification.Name("userDidLogout")
}

final class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let baseURL: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private var _testToken: String?
    
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
    #endif
    
    static var apiEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(Int64(date.timeIntervalSince1970 * 1000))
        }
        return encoder
    }
    
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
    
    private func buildRequest(
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
        
        if let token = _testToken ?? SessionStore.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
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
}

struct EmptyResponse: Decodable {}

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

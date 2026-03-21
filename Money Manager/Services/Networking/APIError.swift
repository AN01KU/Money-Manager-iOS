//
//  APIError.swift
//  Money Manager
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    case unauthorized
    case notFound
    case conflict
    case serverError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let message):
            return message ?? "HTTP Error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Session expired. Please log in again."
        case .notFound:
            return "Resource not found"
        case .conflict:
            return "Conflict detected. Data will be synced."
        case .serverError:
            return "Server error. Please try again later."
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

extension APIError {
    init(from httpResponse: HTTPURLResponse, data: Data?) {
        let message = try? JSONDecoder().decode(ErrorResponse.self, from: data ?? Data()).message
        
        switch httpResponse.statusCode {
        case 401:
            self = .unauthorized
        case 404:
            self = .notFound
        case 409:
            self = .conflict
        case 500...599:
            self = .serverError
        default:
            self = .httpError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}

private struct ErrorResponse: Decodable {
    private let errorValue: String?
    private let messageValue: String?
    
    var message: String? {
        errorValue ?? messageValue
    }
    
    enum CodingKeys: String, CodingKey {
        case error
        case message
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.errorValue = try container.decodeIfPresent(String.self, forKey: .error)
        self.messageValue = try container.decodeIfPresent(String.self, forKey: .message)
    }
}

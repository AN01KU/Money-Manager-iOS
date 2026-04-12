//
//  APIError.swift
//  Money Manager
//

import Foundation

enum APIError: Error, LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    case unauthorized
    case notFound
    case conflict
    case syncSessionInvalid(reason: String)
    case serverError
    case unknown
    case missingTestData(String)
    
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
        case .syncSessionInvalid(let reason):
            return "Sync session rejected: \(reason)"
        case .serverError:
            return "Server error. Please try again later."
        case .unknown:
            return "An unknown error occurred"
        case .missingTestData(let context):
            return "Missing test data: \(context)"
        }
    }
    
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.unauthorized, .unauthorized),
             (.notFound, .notFound),
             (.conflict, .conflict),
             (.serverError, .serverError),
             (.unknown, .unknown):
            return true
        case let (.httpError(lCode, lMsg), .httpError(rCode, rMsg)):
            return lCode == rCode && lMsg == rMsg
        case (.decodingError, .decodingError),
             (.encodingError, .encodingError),
             (.networkError, .networkError):
            return true
        case let (.missingTestData(lCtx), .missingTestData(rCtx)):
            return lCtx == rCtx
        case let (.syncSessionInvalid(lReason), .syncSessionInvalid(rReason)):
            return lReason == rReason
        default:
            return false
        }
    }
}

extension APIError {
    init(from httpResponse: HTTPURLResponse, data: Data?) {
        let message = Self.parseErrorMessage(from: data)

        switch httpResponse.statusCode {
        case 401:
            if let message, !message.isEmpty {
                self = .httpError(statusCode: 401, message: message)
            } else {
                self = .unauthorized
            }
        case 404:
            self = .notFound
        case 409:
            if let reason = Self.parseSyncSessionReason(from: data) {
                self = .syncSessionInvalid(reason: reason)
            } else {
                self = .conflict
            }
        case 500...599:
            self = .serverError
        default:
            self = .httpError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    private static func parseErrorMessage(from data: Data?) -> String? {
        guard let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json["error"] as? String ?? json["message"] as? String
    }

    private static let syncSessionReasons: Set<String> = [
        "SYNC_SESSION_MISMATCH",
        "SYNC_SESSION_EXPIRED",
        "SYNC_SESSION_NOT_FOUND"
    ]

    private static func parseSyncSessionReason(from data: Data?) -> String? {
        guard let data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let reason = json["reason"] as? String,
              syncSessionReasons.contains(reason)
        else { return nil }
        return reason
    }
}

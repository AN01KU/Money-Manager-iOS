//
//  ErrorHandler.swift
//  Money Manager
//
//  Created for centralized error handling and logging
//

import Foundation

/// Centralized error handler for consistent error management across the app
final class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    /// Log an error for debugging
    func logError(_ error: Error, context: String = "") {
        let errorMessage = error.localizedDescription
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        #if DEBUG
        let contextLabel = context.isEmpty ? "" : " [\(context)]"
        print("❌ ERROR\(contextLabel) at \(timestamp): \(errorMessage)")
        #endif
    }
    
    /// Get user-friendly error message from any error
    func getUserFriendlyMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.errorDescription ?? "An error occurred"
        }
        
        return error.localizedDescription
    }
    
    /// Determine if error is network-related
    func isNetworkError(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            if case .networkError = apiError {
                return true
            }
        }
        return false
    }
    
    /// Determine if error is authentication-related
    func isAuthError(_ error: Error) -> Bool {
        if let apiError = error as? APIError {
            if case .unauthorized = apiError {
                return true
            }
        }
        return false
    }
}

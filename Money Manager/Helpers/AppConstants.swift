//
//  AppConstants.swift
//  Money Manager
//
//  Created for centralized app constants and configuration
//

import Foundation

/// Environment-driven configuration resolved from Info.plist (populated by xcconfig).
/// Single source of truth for base URL and test credentials across the app and test targets.
///
/// Computed vars are used throughout so Bundle.main (which is @MainActor in Swift 6)
/// is only accessed at call sites, avoiding static initializer isolation issues.
enum AppConfig {
    // nonisolated so these can be called from Sendable / nonisolated contexts
    // (the project uses -default-isolation=MainActor).
    // Bundle.main.object(forInfoDictionaryKey:) is safe to call from any thread
    // because Info.plist is immutable after launch.
    nonisolated(unsafe) private static func plistValue(_ key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
    }

    /// Full base URL assembled from API_BASE_SCHEME and API_BASE_HOST xcconfig keys.
    nonisolated(unsafe) static var baseURL: URL {
        let scheme = plistValue("API_BASE_SCHEME").isEmpty ? "https" : plistValue("API_BASE_SCHEME")
        let host   = plistValue("API_BASE_HOST")
        return URL(string: "\(scheme)://\(host)")!
    }

    #if DEBUG
    nonisolated(unsafe) static var testInviteCode: String { plistValue("TEST_INVITE_CODE") }
    nonisolated(unsafe) static var testUsername: String   { plistValue("TEST_USERNAME") }
    nonisolated(unsafe) static var testEmail: String      { plistValue("TEST_EMAIL") }
    nonisolated(unsafe) static var testPassword: String   { plistValue("TEST_PASSWORD") }
    #endif
}

/// App-wide constants
enum AppConstants {
    /// Animation durations
    enum Animation {
        static let quick: CGFloat = 0.2
        static let standard: CGFloat = 0.3
        static let moderate: CGFloat = 0.5
    }
    
    /// API timeout values
    enum API {
        static let defaultTimeout: TimeInterval = 30
        static let shortTimeout: TimeInterval = 10
    }
    
    /// Quick amount presets for transaction entry
    enum QuickAmounts {
        static let personal: [Double] = [100, 500, 1000]
        static let shared: [Double] = [500, 1000, 2000]
    }
    
    /// Formatting
    enum Format {
        static let currency = "₹"
        static let decimalPlaces = 2
    }
    
    /// Date formats
    enum DateFormat {
        static let monthYear = "MMMM yyyy"
        static let display = "MMM dd, yyyy"
        static let iso8601 = ISO8601DateFormatter()
    }
    
    /// UI measurements
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let fabSize: CGFloat = 56
        static let padding: CGFloat = 16
    }
    
    /// Validation
    enum Validation {
        static let minAmountValue: Double = 0.01
        static let maxAmountValue: Double = 999999.99
        static let minBudgetLimit: Double = 100
    }
}

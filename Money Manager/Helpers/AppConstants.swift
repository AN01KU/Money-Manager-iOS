//
//  AppConstants.swift
//  Money Manager
//
//  Created for centralized app constants and configuration
//

import CryptoKit
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
    
    /// UI measurements — sourced from design token spec (4pt base grid)
    enum UI {
        // MARK: Spacing
        static let spacingXS:  CGFloat = 4   // icon inner padding, micro gaps
        static let spacingSM:  CGFloat = 8   // icon-to-label gap
        static let spacing12:  CGFloat = 12  // compact card padding
        static let spacing14:  CGFloat = 14  // row vertical padding
        static let padding:    CGFloat = 16  // card padding, section inset
        static let spacing20:  CGFloat = 20  // large title padding, FAB margin
        static let spacing24:  CGFloat = 24  // between card sections
        static let spacing32:  CGFloat = 32  // between major groups
        static let spacingXL:  CGFloat = 40  // page top/bottom breathing room

        // MARK: Corner Radii
        static let radiusXS:   CGFloat = 8   // chips, period pickers
        static let radius10:   CGFloat = 10  // segment controls
        static let radiusSM:   CGFloat = 12  // search bar, inputs
        static let radius14:   CGFloat = 14  // buttons, action rows
        static let cornerRadius: CGFloat = 16 // cards, list groups
        static let radiusSheet: CGFloat = 20 // bottom sheets, modals
        static let radiusFAB:  CGFloat = 28  // FAB (56 ÷ 2)

        // MARK: Component sizes
        static let fabSize:       CGFloat = 56
        static let iconSize:      CGFloat = 24  // standard icon canvas
        static let iconSizeSM:    CGFloat = 20  // compact icon (transaction rows)
        static let avatarSize:    CGFloat = 38  // category avatar in list rows
        static let iconBadgeSize: CGFloat = 36  // settings / list icon badge (rounded square)
        static let profileAvatarSize: CGFloat = 46  // profile circle in settings / profile card
    }
    
    /// Validation
    enum Validation {
        static let minAmountValue: Double = 0.01
        static let maxAmountValue: Double = 999999.99
        static let minBudgetLimit: Double = 100
    }
}

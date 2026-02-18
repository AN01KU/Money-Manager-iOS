//
//  AppConstants.swift
//  Money Manager
//
//  Created for centralized app constants and configuration
//

import Foundation

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
    
    /// Quick amount presets for expense entry
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

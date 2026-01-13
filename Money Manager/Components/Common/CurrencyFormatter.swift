//
//  CurrencyFormatter.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import Foundation

struct CurrencyFormatter {
    static func format(_ amount: Double, showDecimals: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = showDecimals ? 2 : 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₹\(Int(amount))"
    }
    
    static func formatWithoutSymbol(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
}

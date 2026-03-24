//
//  CurrencyFormatter.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import Foundation

struct CurrencyFormatter {
    static let currencySymbols: [String: String] = [
        "INR": "₹",
        "USD": "$",
        "EUR": "€",
        "GBP": "£",
        "JPY": "¥",
        "AUD": "A$",
        "CAD": "C$",
        "SGD": "S$",
        "AED": "د.إ",
        "SAR": "﷼"
    ]

    static let supportedCurrencies: [(code: String, name: String, symbol: String)] = [
        ("INR", "Indian Rupee", "₹"),
        ("USD", "US Dollar", "$"),
        ("EUR", "Euro", "€"),
        ("GBP", "British Pound", "£"),
        ("JPY", "Japanese Yen", "¥"),
        ("AUD", "Australian Dollar", "A$"),
        ("CAD", "Canadian Dollar", "C$"),
        ("SGD", "Singapore Dollar", "S$"),
        ("AED", "UAE Dirham", "د.إ"),
        ("SAR", "Saudi Riyal", "﷼")
    ]

    static var currentCode: String {
        UserDefaults.standard.string(forKey: "selectedCurrency") ?? "INR"
    }

    static var currentSymbol: String {
        currencySymbols[currentCode] ?? "₹"
    }

    static func format(_ amount: Double, showDecimals: Bool = false) -> String {
        let code = currentCode
        let symbol = currencySymbols[code] ?? "₹"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.currencySymbol = symbol
        formatter.maximumFractionDigits = showDecimals ? 2 : 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(symbol)\(Int(amount))"
    }

    static func formatWithoutSymbol(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
}

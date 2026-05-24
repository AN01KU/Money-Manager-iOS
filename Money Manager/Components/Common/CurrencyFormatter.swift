//
//  CurrencyFormatter.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import Foundation

struct Currency: Equatable {
    let code: String
    let symbol: String
    let name: String

    static let `default` = Currency(code: "INR", symbol: "₹", name: "Indian Rupee")

    static let all: [Currency] = [
        .default,
        Currency(code: "USD", symbol: "$",    name: "US Dollar"),
        Currency(code: "EUR", symbol: "€",    name: "Euro"),
        Currency(code: "GBP", symbol: "£",    name: "British Pound"),
        Currency(code: "JPY", symbol: "¥",    name: "Japanese Yen"),
        Currency(code: "AUD", symbol: "A$",   name: "Australian Dollar"),
        Currency(code: "CAD", symbol: "C$",   name: "Canadian Dollar"),
        Currency(code: "SGD", symbol: "S$",   name: "Singapore Dollar"),
        Currency(code: "AED", symbol: "د.إ",  name: "UAE Dirham"),
        Currency(code: "SAR", symbol: "﷼",    name: "Saudi Riyal")
    ]

    private static let byCode: [String: Currency] = Dictionary(uniqueKeysWithValues: all.map { ($0.code, $0) })

    static func find(code: String) -> Currency {
        byCode[code] ?? .default
    }
}

@MainActor
struct CurrencyFormatter {
    static var supportedCurrencies: [Currency] { Currency.all }

    static var currencySymbols: [String: String] {
        Dictionary(uniqueKeysWithValues: Currency.all.map { ($0.code, $0.symbol) })
    }

    static var currentCode: String {
        UserDefaults.standard.string(forKey: UserDefaults.Keys.selectedCurrency.rawValue) ?? Currency.default.code
    }

    static var currentSymbol: String {
        Currency.find(code: currentCode).symbol
    }

    static func format(_ amount: Double, showDecimals: Bool = false) -> String {
        let currency = Currency.find(code: currentCode)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        formatter.currencySymbol = currency.symbol
        formatter.maximumFractionDigits = showDecimals ? 2 : 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency.symbol)\(Int(amount))"
    }

    static func formatWithoutSymbol(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
}

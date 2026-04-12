//
//  ScreenshotTag.swift
//  Money Manager UITests
//
//  Defines all screenshot tags. Each tag maps to a filename saved in Screenshots/.
//  To add a new screen: add a case here and capture it in ScreenshotGenerator.
//

import Foundation

enum ScreenshotTag: String, CaseIterable {
    case overview              = "overview"
    case transactionsList      = "transactions-list"
    case addTransaction        = "transaction-add"
    case budgets               = "budget-set"
    case recurringList         = "transaction-recurring-list"
    case categories            = "categories"
    case settings              = "settings"
    case groupsList            = "groups-list"
    case groupDetail           = "group-detail"
    case groupBalances         = "group-balances"

    /// Filename written to the Screenshots/ folder (no extension)
    var filename: String { rawValue }
}

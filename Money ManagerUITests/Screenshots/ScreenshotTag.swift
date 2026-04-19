//
//  ScreenshotTag.swift
//  Money Manager UITests
//
//  Defines all screenshot tags. Each tag maps to a filename saved in Screenshots/.
//  To add a new screen: add a case here and capture it in ScreenshotGenerator.
//

import Foundation

enum ScreenshotTag: String, CaseIterable {
    // MARK: - Main Tabs
    case overview              = "overview"
    case transactionsList      = "transactions-list"
    case groupsList            = "groups-list"
    case settings              = "settings"

    // MARK: - Transactions
    case addTransaction        = "transaction-add"
    case addTransactionShared  = "transaction-add-shared"
    case transactionDetail     = "transaction-detail"
    case transactionEdit       = "transaction-edit"

    // MARK: - Settings Sub-pages
    case budgets               = "budget-set"
    case recurringList         = "transaction-recurring-list"
    case categories            = "categories"
    case addCategory           = "category-add"
    case categoryEditor        = "category-editor"
    case currencyPicker        = "currency-picker"
    case exportData            = "export-data"
    case editProfile           = "edit-profile"

    // MARK: - Groups
    case groupDetail           = "group-detail"
    case groupBalances         = "group-balances"
    case groupMembers          = "group-members"
    case groupTransactionDetail = "group-transaction-detail"
    case groupAddTransaction   = "group-add-transaction"
    case recordSettlement      = "group-record-settlement"
    case groupAddMember        = "group-add-member"

    /// Filename written to the Screenshots/ folder (no extension)
    var filename: String { rawValue }
}

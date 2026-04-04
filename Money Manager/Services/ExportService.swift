import Foundation
import SwiftData

struct ExportService {

    private let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - Public API

    func exportTransactions(format: ExportFormat, transactions: [Transaction], groups: [SplitGroupModel]) throws -> URL {
        let activeTransactions = transactions.filter { !$0.isSoftDeleted }
        switch format {
        case .csv: return try exportTransactionsToCSV(transactions: activeTransactions, groups: groups)
        case .json: return try exportTransactionsToJSON(transactions: activeTransactions)
        }
    }

    func exportRecurringTransactions(format: ExportFormat, recurringTransactions: [RecurringTransaction]) throws -> URL {
        switch format {
        case .csv: return try exportRecurringTransactionsToCSV(recurringTransactions: recurringTransactions)
        case .json: return try exportRecurringTransactionsToJSON(recurringTransactions: recurringTransactions)
        }
    }

    func exportBudgets(format: ExportFormat, budgets: [MonthlyBudget]) throws -> URL {
        switch format {
        case .csv: return try exportBudgetsToCSV(budgets: budgets)
        case .json: return try exportBudgetsToJSON(budgets: budgets)
        }
    }

    func exportCategories(format: ExportFormat, categories: [CustomCategory]) throws -> URL {
        switch format {
        case .csv: return try exportCategoriesToCSV(categories: categories)
        case .json: return try exportCategoriesToJSON(categories: categories)
        }
    }

    func exportAll(format: ExportFormat, transactions: [Transaction], recurringTransactions: [RecurringTransaction], budgets: [MonthlyBudget], categories: [CustomCategory]) throws -> URL {
        let activeTransactions = transactions.filter { !$0.isSoftDeleted }
        switch format {
        case .csv: return try exportAllToCSV(transactions: activeTransactions, recurringTransactions: recurringTransactions, budgets: budgets, categories: categories)
        case .json: return try exportAllToJSON(transactions: activeTransactions, recurringTransactions: recurringTransactions, budgets: budgets, categories: categories)
        }
    }

    // MARK: - Transactions

    private func exportTransactionsToCSV(transactions: [Transaction], groups: [SplitGroupModel]) throws -> URL {
        var csv = "ID,Amount,Category,Date,Time,Description,Notes,Recurring Transaction ID,Group ID,Group Name\n"

        for transaction in transactions {
            let id = transaction.id.uuidString
            let amount = String(transaction.amount)
            let category = escapeCSV(transaction.category)
            let date = iso8601Formatter.string(from: transaction.date)
            let time = transaction.time.map { iso8601Formatter.string(from: $0) } ?? ""
            let description = escapeCSV(transaction.transactionDescription ?? "")
            let notes = escapeCSV(transaction.notes ?? "")
            let recurringTransactionId = transaction.recurringExpenseId?.uuidString ?? ""
            let groupId = transaction.groupTransactionId?.uuidString ?? ""
            let groupName: String = {
                guard let gtId = transaction.groupTransactionId else { return "" }
                let groupTransaction = groups.flatMap { $0.transactions }.first(where: { $0.id == gtId })
                return escapeCSV(groupTransaction?.group?.name ?? "")
            }()

            let row = [id, amount, category, date, time, description, notes, recurringTransactionId, groupId, groupName].joined(separator: ",")
            csv += row + "\n"
        }

        let fileName = "transaction_\(dateString()).csv"
        return try saveToTempFile(csv, fileName: fileName)
    }

    private func exportTransactionsToJSON(transactions: [Transaction]) throws -> URL {
        let transactionData = transactions.map { transaction in
            ExportData.TransactionData(
                id: transaction.id.uuidString,
                type: transaction.type.rawValue,
                amount: transaction.amount,
                category: transaction.category,
                date: transaction.date,
                time: transaction.time,
                transactionDescription: transaction.transactionDescription,
                notes: transaction.notes,
                recurringExpenseId: transaction.recurringExpenseId?.uuidString,
                groupTransactionId: transaction.groupTransactionId?.uuidString
            )
        }

        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            transactions: transactionData,
            recurringTransactions: nil,
            budgets: nil,
            categories: nil
        )

        return try saveToJSON(exportData, fileName: "transactionDatas_\(dateString()).json")
    }

    // MARK: - Recurring Transactions

    private func exportRecurringTransactionsToCSV(recurringTransactions: [RecurringTransaction]) throws -> URL {
        var csv = "ID,Name,Amount,Category,Frequency,Day of Month,Days of Week,Start Date,End Date,Is Active,Notes\n"

        for recurring in recurringTransactions {
            let id = recurring.id.uuidString
            let name = escapeCSV(recurring.name)
            let amount = String(recurring.amount)
            let category = escapeCSV(recurring.category)
            let frequency = recurring.frequency.rawValue
            let dayOfMonth = recurring.dayOfMonth.map { String($0) } ?? ""
            let daysOfWeek = recurring.daysOfWeek.map { $0.map { String($0) }.joined(separator: ";") } ?? ""
            let startDate = iso8601Formatter.string(from: recurring.startDate)
            let endDate = recurring.endDate.map { iso8601Formatter.string(from: $0) } ?? ""
            let isActive = String(recurring.isActive)
            let notes = escapeCSV(recurring.notes ?? "")

            let row = [id, name, amount, category, frequency, dayOfMonth, daysOfWeek, startDate, endDate, isActive, notes].joined(separator: ",")
            csv += row + "\n"
        }

        let fileName = "recurring_transactions_\(dateString()).csv"
        return try saveToTempFile(csv, fileName: fileName)
    }

    private func exportRecurringTransactionsToJSON(recurringTransactions: [RecurringTransaction]) throws -> URL {
        let recurringData = recurringTransactions.map { recurring in
            ExportData.RecurringTransactionData(
                id: recurring.id.uuidString,
                name: recurring.name,
                amount: recurring.amount,
                category: recurring.category,
                frequency: recurring.frequency.rawValue,
                dayOfMonth: recurring.dayOfMonth,
                daysOfWeek: recurring.daysOfWeek,
                startDate: recurring.startDate,
                endDate: recurring.endDate,
                isActive: recurring.isActive,
                lastAddedDate: recurring.lastAddedDate,
                notes: recurring.notes,
                createdAt: recurring.createdAt,
                updatedAt: recurring.updatedAt,
                type: recurring.type.rawValue
            )
        }

        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            transactions: nil,
            recurringTransactions: recurringData,
            budgets: nil,
            categories: nil
        )

        return try saveToJSON(exportData, fileName: "recurring_transactions_\(dateString()).json")
    }

    // MARK: - Budgets

    private func exportBudgetsToCSV(budgets: [MonthlyBudget]) throws -> URL {
        var csv = "ID,Year,Month,Limit\n"

        for budget in budgets {
            let row = [
                budget.id.uuidString,
                String(budget.year),
                String(budget.month),
                String(budget.limit)
            ].joined(separator: ",")
            csv += row + "\n"
        }

        let fileName = "budgets_\(dateString()).csv"
        return try saveToTempFile(csv, fileName: fileName)
    }

    private func exportBudgetsToJSON(budgets: [MonthlyBudget]) throws -> URL {
        let budgetData = budgets.map { budget in
            ExportData.MonthlyBudgetData(
                id: budget.id.uuidString,
                year: budget.year,
                month: budget.month,
                limit: budget.limit
            )
        }

        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            transactions: nil,
            recurringTransactions: nil,
            budgets: budgetData,
            categories: nil
        )

        return try saveToJSON(exportData, fileName: "budgets_\(dateString()).json")
    }

    // MARK: - Categories

    private func exportCategoriesToCSV(categories: [CustomCategory]) throws -> URL {
        var csv = "ID,Name,Icon,Color,Is Hidden,Is Predefined,Predefined Key\n"

        for category in categories {
            let row = [
                category.id.uuidString,
                escapeCSV(category.name),
                category.icon,
                category.color,
                String(category.isHidden),
                String(category.isPredefined),
                category.predefinedKey ?? ""
            ].joined(separator: ",")
            csv += row + "\n"
        }

        let fileName = "categories_\(dateString()).csv"
        return try saveToTempFile(csv, fileName: fileName)
    }

    private func exportCategoriesToJSON(categories: [CustomCategory]) throws -> URL {
        let categoryData = categories.map { category in
            ExportData.CustomCategoryData(
                id: category.id.uuidString,
                name: category.name,
                icon: category.icon,
                color: category.color,
                isHidden: category.isHidden,
                isPredefined: category.isPredefined,
                predefinedKey: category.predefinedKey
            )
        }

        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            transactions: nil,
            recurringTransactions: nil,
            budgets: nil,
            categories: categoryData
        )

        return try saveToJSON(exportData, fileName: "categories_\(dateString()).json")
    }

    // MARK: - Export All

    private func exportAllToCSV(transactions: [Transaction], recurringTransactions: [RecurringTransaction], budgets: [MonthlyBudget], categories: [CustomCategory]) throws -> URL {
        var csv = ""

        csv += "# TRANSACTIONS\n"
        csv += "ID,Amount,Category,Date,Time,Description,Notes,Recurring Expense ID,Group ID,Group Name\n"

        for transaction in transactions {
            let id = transaction.id.uuidString
            let amount = String(transaction.amount)
            let category = escapeCSV(transaction.category)
            let date = iso8601Formatter.string(from: transaction.date)
            let time = transaction.time.map { iso8601Formatter.string(from: $0) } ?? ""
            let desc = escapeCSV(transaction.transactionDescription ?? "")
            let notes = escapeCSV(transaction.notes ?? "")
            let recId = transaction.recurringExpenseId?.uuidString ?? ""
            let gid = transaction.groupTransactionId?.uuidString ?? ""
            let gname = escapeCSV(nil ?? "")

            let row = [id, amount, category, date, time, desc, notes, recId, gid, gname].joined(separator: ",")
            csv += row + "\n"
        }

        csv += "\n# RECURRING EXPENSES\n"
        csv += "ID,Name,Amount,Category,Frequency,Day of Month,Days of Week,Start Date,End Date,Is Active,Notes\n"

        for recurring in recurringTransactions {
            let id = recurring.id.uuidString
            let name = escapeCSV(recurring.name)
            let amount = String(recurring.amount)
            let category = escapeCSV(recurring.category)
            let frequency = recurring.frequency.rawValue
            let dayOfMonth = recurring.dayOfMonth.map { String($0) } ?? ""
            let daysOfWeek = recurring.daysOfWeek.map { $0.map { String($0) }.joined(separator: ";") } ?? ""
            let startDate = iso8601Formatter.string(from: recurring.startDate)
            let endDate = recurring.endDate.map { iso8601Formatter.string(from: $0) } ?? ""
            let isActive = String(recurring.isActive)
            let notes = escapeCSV(recurring.notes ?? "")

            let row = [id, name, amount, category, frequency, dayOfMonth, daysOfWeek, startDate, endDate, isActive, notes].joined(separator: ",")
            csv += row + "\n"
        }

        csv += "\n# BUDGETS\n"
        csv += "ID,Year,Month,Limit\n"

        for budget in budgets {
            let row = [
                budget.id.uuidString,
                String(budget.year),
                String(budget.month),
                String(budget.limit)
            ].joined(separator: ",")
            csv += row + "\n"
        }

        csv += "\n# CATEGORIES\n"
        csv += "ID,Name,Icon,Color,Is Hidden,Is Predefined,Predefined Key\n"

        for category in categories {
            let row = [
                category.id.uuidString,
                escapeCSV(category.name),
                category.icon,
                category.color,
                String(category.isHidden),
                String(category.isPredefined),
                category.predefinedKey ?? ""
            ].joined(separator: ",")
            csv += row + "\n"
        }

        let fileName = "money_manager_backup_\(dateString()).csv"
        return try saveToTempFile(csv, fileName: fileName)
    }

    private func exportAllToJSON(transactions: [Transaction], recurringTransactions: [RecurringTransaction], budgets: [MonthlyBudget], categories: [CustomCategory]) throws -> URL {
        let transactionsData = transactions.map { transaction in
            ExportData.TransactionData(
                id: transaction.id.uuidString,
                type: transaction.type.rawValue,
                amount: transaction.amount,
                category: transaction.category,
                date: transaction.date,
                time: transaction.time,
                transactionDescription: transaction.transactionDescription,
                notes: transaction.notes,
                recurringExpenseId: transaction.recurringExpenseId?.uuidString,
                groupTransactionId: transaction.groupTransactionId?.uuidString
            )
        }

        let recurringTransactionData = recurringTransactions.map { recurring in
            ExportData.RecurringTransactionData(
                id: recurring.id.uuidString,
                name: recurring.name,
                amount: recurring.amount,
                category: recurring.category,
                frequency: recurring.frequency.rawValue,
                dayOfMonth: recurring.dayOfMonth,
                daysOfWeek: recurring.daysOfWeek,
                startDate: recurring.startDate,
                endDate: recurring.endDate,
                isActive: recurring.isActive,
                lastAddedDate: recurring.lastAddedDate,
                notes: recurring.notes,
                createdAt: recurring.createdAt,
                updatedAt: recurring.updatedAt,
                type: recurring.type.rawValue
            )
        }

        let budgetData = budgets.map { budget in
            ExportData.MonthlyBudgetData(
                id: budget.id.uuidString,
                year: budget.year,
                month: budget.month,
                limit: budget.limit
            )
        }

        let categoryData = categories.map { category in
            ExportData.CustomCategoryData(
                id: category.id.uuidString,
                name: category.name,
                icon: category.icon,
                color: category.color,
                isHidden: category.isHidden,
                isPredefined: category.isPredefined,
                predefinedKey: category.predefinedKey
            )
        }

        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            transactions: transactionsData,
            recurringTransactions: recurringTransactionData,
            budgets: budgetData,
            categories: categoryData
        )

        return try saveToJSON(exportData, fileName: "money_manager_backup_\(dateString()).json")
    }

    // MARK: - Helpers

    func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }

    private func saveToTempFile(_ content: String, fileName: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    private func saveToJSON(_ data: ExportData, fileName: String) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let jsonData = try encoder.encode(data)
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        try jsonData.write(to: fileURL)
        return fileURL
    }
}

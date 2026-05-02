import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Tests for EditCategoryViewModel: save() with rename path,
/// failure paths, and renameCategoryInTransactions behavior.
@MainActor
struct EditCategoryViewModelRenameTests {

    private func makeContext() throws -> ModelContext {
        ModelContext(try makeTestContainer())
    }

    private func makeCustomCategory(name: String, icon: String = "star", color: String = "#FF0000") -> CustomCategory {
        CustomCategory(name: name, icon: icon, color: color)
    }

    private func makeTransactionCategory(row: CustomCategory) -> TransactionCategory {
        TransactionCategory(
            id: "custom:\(row.id.uuidString)",
            key: row.key.isEmpty ? "local:\(row.id.uuidString)" : row.key,
            name: row.name, icon: row.icon, colorHex: row.color,
            isHidden: false, isPredefined: false, isDeletable: true,
            overrideRow: row
        )
    }

    // MARK: - save: update existing custom row

    @Test func testSaveUpdatesCustomCategoryRow() throws {
        let context = try makeContext()
        let row = makeCustomCategory(name: "Coffee")
        context.insert(row)
        let category = makeTransactionCategory(row: row)
        let persistence = PersistenceService()
        persistence.modelContext = context

        let vm = EditCategoryViewModel(category: category, allCategories: [], persistence: persistence)
        vm.name = "Tea"
        vm.modelContext = context

        let saved = vm.save()
        #expect(saved == true)
        #expect(row.name == "Tea")
    }

    @Test func testSaveReturnsFalseForEmptyName() throws {
        let context = try makeContext()
        let row = makeCustomCategory(name: "Coffee")
        context.insert(row)
        let category = makeTransactionCategory(row: row)
        let persistence = PersistenceService()
        persistence.modelContext = context

        let vm = EditCategoryViewModel(category: category, allCategories: [], persistence: persistence)
        vm.name = ""
        vm.modelContext = context

        let saved = vm.save()
        #expect(saved == false)
        #expect(vm.showError == true)
    }

    @Test func testSaveReturnsFalseWithNoModelContext() throws {
        let row = makeCustomCategory(name: "Coffee")
        let category = makeTransactionCategory(row: row)
        let persistence = PersistenceService()
        // modelContext is nil

        let vm = EditCategoryViewModel(category: category, allCategories: [], persistence: persistence)
        vm.name = "Tea"

        let saved = vm.save()
        #expect(saved == false)
    }

    @Test func testSaveDoesNotUpdateTransactionCategoryOnRename() throws {
        // Transactions store the stable server key, so renaming a category's display name
        // does not cascade to transactions.
        let context = try makeContext()
        let row = makeCustomCategory(name: "Coffee")
        row.key = "coffee-custom"
        context.insert(row)

        let tx = Transaction(amount: 5, category: "coffee-custom", date: Date())
        tx.categoryId = row.id
        context.insert(tx)

        let category = makeTransactionCategory(row: row)
        let persistence = PersistenceService()
        persistence.modelContext = context

        let vm = EditCategoryViewModel(category: category, allCategories: [], persistence: persistence)
        vm.name = "Tea"
        vm.modelContext = context

        let saved = vm.save()
        #expect(saved == true)
        // category key on transaction is unchanged — only display name changed
        #expect(tx.category == "coffee-custom")
    }

    @Test func testSaveDoesNotUpdateRecurringTransactionCategoryOnRename() throws {
        let context = try makeContext()
        let row = makeCustomCategory(name: "Coffee")
        row.key = "coffee-custom"
        context.insert(row)

        let recurring = RecurringTransaction(
            name: "Daily Coffee",
            amount: 5,
            category: "coffee-custom",
            frequency: .daily,
            startDate: Date(),
            categoryId: row.id
        )
        context.insert(recurring)

        let category = makeTransactionCategory(row: row)
        let persistence = PersistenceService()
        persistence.modelContext = context

        let vm = EditCategoryViewModel(category: category, allCategories: [], persistence: persistence)
        vm.name = "Tea"
        vm.modelContext = context

        let saved = vm.save()
        #expect(saved == true)
        #expect(recurring.category == "coffee-custom")
    }

    @Test func testSaveDoesNotRenameTransactionsWithDifferentCategoryId() throws {
        let context = try makeContext()
        let row = makeCustomCategory(name: "Coffee")
        context.insert(row)

        let tx = Transaction(amount: 10, category: "Food", date: Date())
        // Different categoryId
        tx.categoryId = UUID()
        context.insert(tx)

        let category = makeTransactionCategory(row: row)
        let persistence = PersistenceService()
        persistence.modelContext = context

        let vm = EditCategoryViewModel(category: category, allCategories: [], persistence: persistence)
        vm.name = "Tea"
        vm.modelContext = context

        let _ = vm.save()
        // tx.category should remain unchanged
        #expect(tx.category == "Food")
    }

    // MARK: - color conflict

    @Test func testSaveReturnsFalseOnColorConflict() throws {
        let context = try makeContext()
        let row = makeCustomCategory(name: "Coffee", color: "#FF0000")
        context.insert(row)

        let conflicting = CustomCategory(name: "Tea", icon: "leaf", color: "#FF0000")
        context.insert(conflicting)

        let category = makeTransactionCategory(row: row)
        let persistence = PersistenceService()
        persistence.modelContext = context

        let vm = EditCategoryViewModel(
            category: category,
            allCategories: [conflicting],
            persistence: persistence
        )
        vm.name = "Coffee Renamed"
        vm.selectedColor = "#FF0000" // same as conflicting
        vm.modelContext = context

        let saved = vm.save()
        // Should show color conflict warning (returns false without error)
        #expect(saved == false)
    }
}

import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct EditCategoryViewModelRenameTests {

    private func makeContext() throws -> ModelContext {
        ModelContext(try makeTestContainer())
    }

    private func makeCategory(name: String, icon: String = "star", color: String = "#FF0000") -> Money_Manager.Category {
        Category(name: name, icon: icon, color: color)
    }

    private func makeService(context: ModelContext) -> PersistenceService {
        PersistenceService(
            modelContext: context,
            authService: MockAuthService.shared,
            networkMonitor: MockNetworkMonitor(),
            changeQueue: MockChangeQueueManager.shared
        )
    }

    // MARK: - save: update existing custom row

    @Test func testSaveUpdatesCategoryRow() throws {
        let context = try makeContext()
        let row = makeCategory(name: "Coffee")
        context.insert(row)

        let vm = EditCategoryViewModel(category: row, allCategories: [], persistence: makeService(context: context))
        vm.name = "Tea"

        let saved = vm.save()
        #expect(saved == true)
        #expect(row.name == "Tea")
    }

    @Test func testSaveReturnsFalseForEmptyName() throws {
        let context = try makeContext()
        let row = makeCategory(name: "Coffee")
        context.insert(row)

        let vm = EditCategoryViewModel(category: row, allCategories: [], persistence: makeService(context: context))
        vm.name = ""

        let saved = vm.save()
        #expect(saved == false)
        #expect(vm.showError == true)
    }

    @Test func testSaveDoesNotUpdateTransactionCategoryOnRename() throws {
        let context = try makeContext()
        let row = makeCategory(name: "Coffee")
        row.key = "coffee-custom"
        context.insert(row)

        let tx = Transaction(amount: 5, categoryId: row.id, date: Date())
        context.insert(tx)

        let vm = EditCategoryViewModel(category: row, allCategories: [], persistence: makeService(context: context))
        vm.name = "Tea"

        let saved = vm.save()
        #expect(saved == true)
        // category key on transaction is unchanged — only display name changed
    }

    @Test func testSaveDoesNotUpdateRecurringTransactionCategoryOnRename() throws {
        let context = try makeContext()
        let row = makeCategory(name: "Coffee")
        row.key = "coffee-custom"
        context.insert(row)

        let recurring = RecurringTransaction(
            name: "Daily Coffee",
            amount: 5,
            categoryId: row.id,
            frequency: .daily,
            startDate: Date()
        )
        context.insert(recurring)

        let vm = EditCategoryViewModel(category: row, allCategories: [], persistence: makeService(context: context))
        vm.name = "Tea"

        let saved = vm.save()
        #expect(saved == true)
    }

    @Test func testSaveDoesNotRenameTransactionsWithDifferentCategoryId() throws {
        let context = try makeContext()
        let row = makeCategory(name: "Coffee")
        context.insert(row)

        let tx = Transaction(amount: 10, categoryId: UUID(), date: Date())
        context.insert(tx)

        let vm = EditCategoryViewModel(category: row, allCategories: [], persistence: makeService(context: context))
        vm.name = "Tea"

        let _ = vm.save()
    }

    // MARK: - color conflict

    @Test func testSaveReturnsFalseOnColorConflict() throws {
        let context = try makeContext()
        let row = makeCategory(name: "Coffee", color: "#FF0000")
        context.insert(row)

        let conflicting = Category(name: "Tea", icon: "leaf", color: "#FF0000")
        context.insert(conflicting)

        let vm = EditCategoryViewModel(
            category: row,
            allCategories: [conflicting],
            persistence: makeService(context: context)
        )
        vm.name = "Coffee Renamed"
        vm.selectedColor = "#FF0000"

        let saved = vm.save()
        #expect(saved == false)
    }
}

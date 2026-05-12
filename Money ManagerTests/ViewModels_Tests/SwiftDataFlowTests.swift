import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@Suite(.serialized)
@MainActor
struct AddRecurringTransactionSwiftDataTests {
    
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Transaction.self, MonthlyBudget.self, Category.self, RecurringTransaction.self,
            configurations: config
        )
    }
    
    @Test
    func testSavePersistsRecurringTransaction() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.modelContext = context
        viewModel.name = "Netflix"
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"
        viewModel.frequency = .monthly
        viewModel.dayOfMonth = 15
        viewModel.notes = "Streaming subscription"
        
        let result = viewModel.save()
        
        #expect(result == true)
        
        let descriptor = FetchDescriptor<RecurringTransaction>()
        let saved = try context.fetch(descriptor)
        
        #expect(saved.count == 1)
        #expect(saved.first?.name == "Netflix")
        #expect(saved.first?.amount == 649)
        #expect(saved.first?.category == "Entertainment")
        #expect(saved.first?.frequency == .monthly)
        #expect(saved.first?.dayOfMonth == 15)
        #expect(saved.first?.notes == "Streaming subscription")
        #expect(saved.first?.isActive == true)
    }
    
    @Test
    func testSaveWithoutEndDateSetsNilEndDate() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.modelContext = context
        viewModel.name = "Gym"
        viewModel.amount = "500"
        viewModel.selectedCategory = "Health"
        viewModel.frequency = .monthly
        viewModel.hasEndDate = false
        
        let result = viewModel.save()
        
        #expect(result == true)
        
        let descriptor = FetchDescriptor<RecurringTransaction>()
        let saved = try context.fetch(descriptor)
        
        #expect(saved.first?.endDate == nil)
    }
    
    @Test
    func testSaveWithEndDatePersistsEndDate() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let endDate = Date()
        
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.modelContext = context
        viewModel.name = "Trial Sub"
        viewModel.amount = "99"
        viewModel.selectedCategory = "Entertainment"
        viewModel.frequency = .monthly
        viewModel.hasEndDate = true
        viewModel.endDate = endDate
        
        let result = viewModel.save()
        
        #expect(result == true)
        
        let descriptor = FetchDescriptor<RecurringTransaction>()
        let saved = try context.fetch(descriptor)
        
        #expect(saved.first?.endDate != nil)
    }
}

@Suite(.serialized)
@MainActor
struct AddCategorySwiftDataTests {
    
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Transaction.self, MonthlyBudget.self, Category.self,
            configurations: config
        )
    }
    
    @Test
    func testSavePersistsCategory() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let viewModel = AddCategoryViewModel()
        viewModel.modelContext = context
        viewModel.name = "Groceries"
        viewModel.selectedIcon = "cart.circle.fill"
        viewModel.selectedColor = "#FF6B6B"
        
        let result = await viewModel.save()
        
        #expect(result == true)
        #expect(viewModel.isSaving == false)
        
        let descriptor = FetchDescriptor<Money_Manager.Category>()
        let saved = try context.fetch(descriptor)
        
        #expect(saved.count == 1)
        #expect(saved.first?.name == "Groceries")
        #expect(saved.first?.icon == "cart.circle.fill")
        #expect(saved.first?.color == "#FF6B6B")
        #expect(saved.first?.isHidden == false)
    }
    
    @Test
    func testSaveTrimsWhitespaceFromName() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let viewModel = AddCategoryViewModel()
        viewModel.modelContext = context
        viewModel.name = "  My Hobby  "
        viewModel.selectedIcon = "star.circle.fill"
        viewModel.selectedColor = "#3498DB"

        let result = await viewModel.save()

        #expect(result == true)

        let descriptor = FetchDescriptor<Money_Manager.Category>()
        let saved = try context.fetch(descriptor)

        #expect(saved.first?.name == "My Hobby")
    }
    
    @Test
    func testSaveMultipleCategoriesPersistsAll() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let vm1 = AddCategoryViewModel()
        vm1.modelContext = context
        vm1.name = "Cat1"
        vm1.selectedIcon = "tag.circle.fill"
        vm1.selectedColor = "#FF6B6B"
        
        let vm2 = AddCategoryViewModel()
        vm2.modelContext = context
        vm2.name = "Cat2"
        vm2.selectedIcon = "star.circle.fill"
        vm2.selectedColor = "#4ECDC4"
        
        let result1 = await vm1.save()
        let result2 = await vm2.save()
        
        #expect(result1 == true)
        #expect(result2 == true)
        
        let descriptor = FetchDescriptor<Money_Manager.Category>()
        let saved = try context.fetch(descriptor)
        
        #expect(saved.count == 2)
    }
}

// MARK: - AddRecurringTransactionViewModel validation

@MainActor
struct AddRecurringTransactionValidationTests {

    private func makeVM(name: String = "Netflix", amount: String = "649", category: String = "Entertainment") -> AddRecurringTransactionViewModel {
        let vm = AddRecurringTransactionViewModel()
        vm.name = name
        vm.amount = amount
        vm.selectedCategory = category
        return vm
    }

    @Test func testSaveWithEmptyNameReturnsFalseAndSetsError() {
        let vm = makeVM(name: "")
        let result = vm.save()
        #expect(result == false)
        #expect(vm.showError == true)
        #expect(!vm.errorMessage.isEmpty)
    }

    @Test func testSaveWithWhitespaceOnlyNameReturnsFalseAndSetsError() {
        let vm = makeVM(name: "   ")
        let result = vm.save()
        #expect(result == false)
        #expect(vm.showError == true)
    }

    @Test func testSaveWithZeroAmountReturnsFalseAndSetsError() {
        let vm = makeVM(amount: "0")
        let result = vm.save()
        #expect(result == false)
        #expect(vm.showError == true)
        #expect(!vm.errorMessage.isEmpty)
    }

    @Test func testSaveWithNegativeAmountReturnsFalseAndSetsError() {
        let vm = makeVM(amount: "-100")
        let result = vm.save()
        #expect(result == false)
        #expect(vm.showError == true)
    }

    @Test func testSaveWithNonNumericAmountReturnsFalseAndSetsError() {
        let vm = makeVM(amount: "abc")
        let result = vm.save()
        #expect(result == false)
        #expect(vm.showError == true)
        #expect(!vm.errorMessage.isEmpty)
    }

    @Test func testSaveWithEmptyAmountReturnsFalseAndSetsError() {
        let vm = makeVM(amount: "")
        let result = vm.save()
        #expect(result == false)
        #expect(vm.showError == true)
    }

    @Test func testIsValidFalseWhenNameEmpty() {
        let vm = makeVM(name: "")
        #expect(vm.isValid == false)
    }

    @Test func testIsValidFalseWhenAmountIsZero() {
        let vm = makeVM(amount: "0")
        #expect(vm.isValid == false)
    }

    @Test func testIsValidFalseWhenAmountIsNonNumeric() {
        let vm = makeVM(amount: "xyz")
        #expect(vm.isValid == false)
    }

    @Test func testIsValidFalseWhenCategoryEmpty() {
        let vm = makeVM(category: "")
        #expect(vm.isValid == false)
    }

    @Test func testIsValidTrueWithValidInputs() {
        let vm = makeVM()
        #expect(vm.isValid == true)
    }
}

@Suite(.serialized)
@MainActor
struct ManageCategoriesSwiftDataTests {
    
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Transaction.self, MonthlyBudget.self, Category.self,
            configurations: config
        )
    }
    
    @Test
    func testHideCategoryPersistsToSwiftData() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let row = Category(name: "Coffee", icon: "star", color: "#FF0000")
        context.insert(row)
        try context.save()

        let category = TransactionCategory(
            id: "custom:\(row.id.uuidString)",
            key: "test-key",
            name: row.name,
            icon: row.icon,
            colorHex: row.color,
            isHidden: row.isHidden,
            isPredefined: false,
            isDeletable: true,
            overrideRow: row
        )

        let viewModel = ManageCategoriesViewModel()
        viewModel.modelContext = context

        viewModel.hideCategory(category)

        let descriptor = FetchDescriptor<Money_Manager.Category>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.first?.isHidden == true)
    }

    @Test
    func testRestoreCategoryPersistsToSwiftData() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let row = Category(name: "Coffee", icon: "star", color: "#FF0000")
        row.isHidden = true
        context.insert(row)
        try context.save()

        let category = TransactionCategory(
            id: "custom:\(row.id.uuidString)",
            key: "test-key",
            name: row.name,
            icon: row.icon,
            colorHex: row.color,
            isHidden: row.isHidden,
            isPredefined: false,
            isDeletable: true,
            overrideRow: row
        )

        let viewModel = ManageCategoriesViewModel()
        viewModel.modelContext = context

        viewModel.restoreCategory(category)

        let descriptor = FetchDescriptor<Money_Manager.Category>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.first?.isHidden == false)
    }

    @Test
    func testHideThenRestoreRoundTrip() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let row = Category(name: "Travel", icon: "star", color: "#00FF00")
        context.insert(row)
        try context.save()

        let viewModel = ManageCategoriesViewModel()
        viewModel.modelContext = context

        let category = TransactionCategory(
            id: "custom:\(row.id.uuidString)",
            key: "test-key",
            name: row.name,
            icon: row.icon,
            colorHex: row.color,
            isHidden: row.isHidden,
            isPredefined: false,
            isDeletable: true,
            overrideRow: row
        )

        viewModel.hideCategory(category)
        #expect(row.isHidden == true)

        viewModel.restoreCategory(category)
        #expect(row.isHidden == false)

        let descriptor = FetchDescriptor<Money_Manager.Category>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.first?.isHidden == false)
    }
}

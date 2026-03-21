import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@Suite(.serialized)
@MainActor
struct AddRecurringExpenseSwiftDataTests {
    
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Expense.self, MonthlyBudget.self, CustomCategory.self, RecurringExpense.self,
            configurations: config
        )
    }
    
    @Test
    func testSavePersistsRecurringExpense() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.configure(modelContext: context)
        viewModel.name = "Netflix"
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"
        viewModel.frequency = "monthly"
        viewModel.dayOfMonth = 15
        viewModel.notes = "Streaming subscription"
        
        let result = viewModel.save()
        
        #expect(result == true)
        
        let descriptor = FetchDescriptor<RecurringExpense>()
        let saved = try context.fetch(descriptor)
        
        #expect(saved.count == 1)
        #expect(saved.first?.name == "Netflix")
        #expect(saved.first?.amount == 649)
        #expect(saved.first?.category == "Entertainment")
        #expect(saved.first?.frequency == "monthly")
        #expect(saved.first?.dayOfMonth == 15)
        #expect(saved.first?.notes == "Streaming subscription")
        #expect(saved.first?.isActive == true)
    }
    
    @Test
    func testSaveWithoutEndDateSetsNilEndDate() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.configure(modelContext: context)
        viewModel.name = "Gym"
        viewModel.amount = "500"
        viewModel.selectedCategory = "Health"
        viewModel.frequency = "monthly"
        viewModel.hasEndDate = false
        
        let result = viewModel.save()
        
        #expect(result == true)
        
        let descriptor = FetchDescriptor<RecurringExpense>()
        let saved = try context.fetch(descriptor)
        
        #expect(saved.first?.endDate == nil)
    }
    
    @Test
    func testSaveWithEndDatePersistsEndDate() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let endDate = Date()
        
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.configure(modelContext: context)
        viewModel.name = "Trial Sub"
        viewModel.amount = "99"
        viewModel.selectedCategory = "Entertainment"
        viewModel.frequency = "monthly"
        viewModel.hasEndDate = true
        viewModel.endDate = endDate
        
        let result = viewModel.save()
        
        #expect(result == true)
        
        let descriptor = FetchDescriptor<RecurringExpense>()
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
            for: Expense.self, MonthlyBudget.self, CustomCategory.self,
            configurations: config
        )
    }
    
    @Test
    func testSavePersistsCategory() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let viewModel = AddCategoryViewModel()
        viewModel.configure(modelContext: context)
        viewModel.name = "Groceries"
        viewModel.selectedIcon = "cart.circle.fill"
        viewModel.selectedColor = "#FF6B6B"
        
        let result = await viewModel.save()
        
        #expect(result == true)
        #expect(viewModel.isSaving == false)
        
        let descriptor = FetchDescriptor<CustomCategory>()
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
        viewModel.configure(modelContext: context)
        viewModel.name = "  Travel  "
        viewModel.selectedIcon = "star.circle.fill"
        viewModel.selectedColor = "#3498DB"
        
        let result = await viewModel.save()
        
        #expect(result == true)
        
        let descriptor = FetchDescriptor<CustomCategory>()
        let saved = try context.fetch(descriptor)
        
        #expect(saved.first?.name == "Travel")
    }
    
    @Test
    func testSaveMultipleCategoriesPersistsAll() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let vm1 = AddCategoryViewModel()
        vm1.configure(modelContext: context)
        vm1.name = "Cat1"
        vm1.selectedIcon = "tag.circle.fill"
        vm1.selectedColor = "#FF6B6B"
        
        let vm2 = AddCategoryViewModel()
        vm2.configure(modelContext: context)
        vm2.name = "Cat2"
        vm2.selectedIcon = "star.circle.fill"
        vm2.selectedColor = "#4ECDC4"
        
        let result1 = await vm1.save()
        let result2 = await vm2.save()
        
        #expect(result1 == true)
        #expect(result2 == true)
        
        let descriptor = FetchDescriptor<CustomCategory>()
        let saved = try context.fetch(descriptor)
        
        #expect(saved.count == 2)
    }
}

@Suite(.serialized)
@MainActor
struct ManageCategoriesSwiftDataTests {
    
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Expense.self, MonthlyBudget.self, CustomCategory.self,
            configurations: config
        )
    }
    
    @Test
    func testHideCategoryPersistsToSwiftData() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let category = CustomCategory(name: "Food", icon: "star", color: "#FF0000")
        context.insert(category)
        try context.save()
        
        let viewModel = ManageCategoriesViewModel()
        viewModel.configure(customCategories: [category], modelContext: context)
        
        viewModel.hideCategory(at: 0)
        
        let descriptor = FetchDescriptor<CustomCategory>()
        let fetched = try context.fetch(descriptor)
        
        #expect(fetched.first?.isHidden == true)
    }
    
    @Test
    func testRestoreCategoryPersistsToSwiftData() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let category = CustomCategory(name: "Food", icon: "star", color: "#FF0000")
        category.isHidden = true
        context.insert(category)
        try context.save()
        
        let viewModel = ManageCategoriesViewModel()
        viewModel.configure(customCategories: [category], modelContext: context)
        
        viewModel.restoreCategory(category)
        
        let descriptor = FetchDescriptor<CustomCategory>()
        let fetched = try context.fetch(descriptor)
        
        #expect(fetched.first?.isHidden == false)
    }
    
    @Test
    func testHideThenRestoreRoundTrip() throws {
        let container = try makeContainer()
        let context = container.mainContext
        
        let category = CustomCategory(name: "Travel", icon: "star", color: "#00FF00")
        context.insert(category)
        try context.save()
        
        let viewModel = ManageCategoriesViewModel()
        viewModel.configure(customCategories: [category], modelContext: context)
        
        viewModel.hideCategory(at: 0)
        #expect(category.isHidden == true)
        
        viewModel.restoreCategory(category)
        #expect(category.isHidden == false)
        
        let descriptor = FetchDescriptor<CustomCategory>()
        let fetched = try context.fetch(descriptor)
        
        #expect(fetched.first?.isHidden == false)
    }
}

import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct ManageCategoriesViewModelTests {
    
    @Test
    func testVisibleCategoriesFiltersOutHidden() {
        let viewModel = ManageCategoriesViewModel()
        
        let visible1 = CustomCategory(name: "Cat1", icon: "star", color: "#FF0000")
        let visible2 = CustomCategory(name: "Cat2", icon: "star", color: "#FF0000")
        let hidden = CustomCategory(name: "Hidden", icon: "star", color: "#FF0000")
        hidden.isHidden = true
        
        viewModel.configure(customCategories: [visible1, visible2, hidden], modelContext: nil)
        
        #expect(viewModel.visibleCategories.count == 2)
    }
    
    @Test
    func testHiddenCategoriesReturnsOnlyHidden() {
        let viewModel = ManageCategoriesViewModel()
        
        let visible = CustomCategory(name: "Visible", icon: "star", color: "#FF0000")
        let hidden1 = CustomCategory(name: "Hidden1", icon: "star", color: "#FF0000")
        let hidden2 = CustomCategory(name: "Hidden2", icon: "star", color: "#FF0000")
        hidden1.isHidden = true
        hidden2.isHidden = true
        
        viewModel.configure(customCategories: [visible, hidden1, hidden2], modelContext: nil)
        
        #expect(viewModel.hiddenCategories.count == 2)
    }
    
    @Test
    func testHideCategorySetsIsHiddenToTrue() {
        let viewModel = ManageCategoriesViewModel()
        
        let category = CustomCategory(name: "Test", icon: "star", color: "#FF0000")
        
        viewModel.configure(customCategories: [category], modelContext: nil)
        
        viewModel.hideCategory(at: 0)
        
        #expect(category.isHidden == true)
    }
    
    @Test
    func testHideCategoryDoesNothingForInvalidIndex() {
        let viewModel = ManageCategoriesViewModel()
        
        let category = CustomCategory(name: "Test", icon: "star", color: "#FF0000")
        
        viewModel.configure(customCategories: [category], modelContext: nil)
        
        viewModel.hideCategory(at: 5)
        
        #expect(category.isHidden == false)
    }
    
    @Test
    func testRestoreCategorySetsIsHiddenToFalse() {
        let viewModel = ManageCategoriesViewModel()
        
        let category = CustomCategory(name: "Test", icon: "star", color: "#FF0000")
        category.isHidden = true
        
        viewModel.configure(customCategories: [category], modelContext: nil)
        
        viewModel.restoreCategory(category)
        
        #expect(category.isHidden == false)
    }
}

@MainActor
struct AddCategoryViewModelTests {
    
    @Test
    func testIconOptionsContainsStandardIcons() {
        let viewModel = AddCategoryViewModel()
        
        #expect(AddCategoryViewModel.iconOptions.contains("tag.circle.fill"))
        #expect(AddCategoryViewModel.iconOptions.contains("cart.circle.fill"))
        #expect(AddCategoryViewModel.iconOptions.contains("star.circle.fill"))
    }
    
    @Test
    func testColorOptionsContainsStandardColors() {
        let viewModel = AddCategoryViewModel()
        
        #expect(AddCategoryViewModel.colorOptions.contains("#FF6B6B"))
        #expect(AddCategoryViewModel.colorOptions.contains("#4ECDC4"))
        #expect(AddCategoryViewModel.colorOptions.contains("#3498DB"))
    }
    
    @Test
    func testDefaultIconIsSet() {
        let viewModel = AddCategoryViewModel()
        
        #expect(viewModel.selectedIcon == "tag.circle.fill")
    }
    
    @Test
    func testDefaultColorIsSet() {
        let viewModel = AddCategoryViewModel()
        
        #expect(viewModel.selectedColor == "#4ECDC4")
    }
    
    @Test
    func testIconOptionsHasMultipleChoices() {
        let viewModel = AddCategoryViewModel()
        
        #expect(AddCategoryViewModel.iconOptions.count > 10)
    }
    
    @Test
    func testColorOptionsHasMultipleChoices() {
        let viewModel = AddCategoryViewModel()
        
        #expect(AddCategoryViewModel.colorOptions.count > 10)
    }
}

@MainActor
struct EditCategoryViewModelTests {
    
    @Test
    func testInitSetsValuesFromCategory() {
        let category = CustomCategory(
            name: "Food",
            icon: "fork.knife",
            color: "#FF0000",
            isPredefined: false,
            predefinedKey: nil
        )
        
        let viewModel = EditCategoryViewModel(category: category)
        
        #expect(viewModel.name == "Food")
        #expect(viewModel.selectedIcon == "fork.knife")
        #expect(viewModel.selectedColor == "#FF0000")
    }
    
    @Test
    func testSaveReturnsFalseWhenNameEmpty() {
        let category = CustomCategory(
            name: "Food",
            icon: "fork.knife",
            color: "#FF0000",
            isPredefined: false,
            predefinedKey: nil
        )
        
        let viewModel = EditCategoryViewModel(category: category)
        viewModel.name = "   "
        
        let result = viewModel.save()
        
        #expect(result == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage.contains("empty"))
    }
    
    @Test
    func testSaveReturnsFalseWhenNameOnlyWhitespace() {
        let category = CustomCategory(
            name: "Food",
            icon: "fork.knife",
            color: "#FF0000",
            isPredefined: false,
            predefinedKey: nil
        )
        
        let viewModel = EditCategoryViewModel(category: category)
        viewModel.name = "  \t  "
        
        let result = viewModel.save()
        
        #expect(result == false)
    }
    
    @Test
    func testInitialStateIsNotSaving() {
        let category = CustomCategory(
            name: "Food",
            icon: "fork.knife",
            color: "#FF0000",
            isPredefined: false,
            predefinedKey: nil
        )
        
        let viewModel = EditCategoryViewModel(category: category)
        
        #expect(viewModel.isSaving == false)
        #expect(viewModel.showError == false)
    }
    
    @Test
    func testColorConflictDetectsSameColor() {
        let category1 = CustomCategory(
            name: "Food",
            icon: "fork.knife",
            color: "#FF0000",
            isPredefined: false,
            predefinedKey: nil
        )
        
        let category2 = CustomCategory(
            name: "Transport",
            icon: "car.fill",
            color: "#FF0000",
            isPredefined: false,
            predefinedKey: nil
        )
        
        let viewModel = EditCategoryViewModel(category: category1, allCategories: [category1, category2])
        
        #expect(viewModel.colorConflictCategory != nil)
    }
    
    @Test
    func testColorConflictIgnoresSameCategory() {
        let category = CustomCategory(
            name: "Food",
            icon: "fork.knife",
            color: "#FF0000",
            isPredefined: false,
            predefinedKey: nil
        )
        
        let viewModel = EditCategoryViewModel(category: category, allCategories: [category])
        
        #expect(viewModel.colorConflictCategory == nil)
    }
    
    @Test
    func testColorConflictIgnoresHiddenCategories() {
        let category1 = CustomCategory(
            name: "Food",
            icon: "fork.knife",
            color: "#FF0000",
            isPredefined: false,
            predefinedKey: nil
        )
        
        let category2 = CustomCategory(
            name: "Hidden",
            icon: "car.fill",
            color: "#FF0000",
            isPredefined: false,
            predefinedKey: nil
        )
        category2.isHidden = true
        
        let viewModel = EditCategoryViewModel(category: category1, allCategories: [category1, category2])
        
        #expect(viewModel.colorConflictCategory == nil)
    }
    
    // MARK: - Delete Category Tests
    
    @Test
    func testDeleteCategorySetsCategoryToDelete() {
        let viewModel = ManageCategoriesViewModel()
        
        let category = CustomCategory(
            name: "Test",
            icon: "star",
            color: "#FF0000",
            isPredefined: false,
            predefinedKey: nil
        )
        
        viewModel.configure(customCategories: [category], modelContext: nil)
        
        viewModel.deleteCategory(category)
        
        #expect(viewModel.categoryToDelete == category)
        #expect(viewModel.showDeleteConfirmation == true)
    }
    
    @Test
    func testDeleteCategoryDoesNothingForOtherCategory() {
        let viewModel = ManageCategoriesViewModel()
        
        let category = CustomCategory(
            name: "Other",
            icon: "ellipsis.circle.fill",
            color: "#95A5A6",
            isPredefined: true,
            predefinedKey: "other"
        )
        
        viewModel.configure(customCategories: [category], modelContext: nil)
        
        viewModel.deleteCategory(category)
        
        #expect(viewModel.categoryToDelete == nil)
        #expect(viewModel.showDeleteConfirmation == false)
    }
    
    @Test
    func testDeleteCategoryAllowsPredefinedCategories() {
        let viewModel = ManageCategoriesViewModel()
        
        let category = CustomCategory(
            name: "Food & Dining",
            icon: "fork.knife",
            color: "#FF0000",
            isPredefined: true,
            predefinedKey: "foodDining"
        )
        
        viewModel.configure(customCategories: [category], modelContext: nil)
        
        viewModel.deleteCategory(category)
        
        #expect(viewModel.categoryToDelete == category)
        #expect(viewModel.showDeleteConfirmation == true)
    }
    
    @Test
    func testConfirmDeleteClearsState() {
        let viewModel = ManageCategoriesViewModel()
        
        let category = CustomCategory(
            name: "Test",
            icon: "star",
            color: "#FF0000",
            isPredefined: false,
            predefinedKey: nil
        )
        
        let schema = Schema([CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        
        viewModel.configure(customCategories: [category], modelContext: context)
        viewModel.deleteCategory(category)
        
        #expect(viewModel.categoryToDelete != nil)
        
        viewModel.confirmDelete()
        
        #expect(viewModel.categoryToDelete == nil)
        #expect(viewModel.showDeleteConfirmation == false)
    }
    
    @Test
    func testConfirmDeleteRemovesFromContext() {
        let category = CustomCategory(
            name: "Test",
            icon: "star",
            color: "#FF0000",
            isPredefined: false,
            predefinedKey: nil
        )
        
        let schema = Schema([CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        context.insert(category)
        try? context.save()
        
        let viewModel = ManageCategoriesViewModel()
        viewModel.configure(customCategories: [category], modelContext: context)
        viewModel.deleteCategory(category)
        viewModel.confirmDelete()
        
        let descriptor = FetchDescriptor<CustomCategory>()
        let remaining = (try? context.fetch(descriptor)) ?? []
        
        #expect(remaining.isEmpty)
    }
    
    @Test
    func testConfirmDeleteReassignsExpensesToOther() {
        let category = CustomCategory(
            name: "Food",
            icon: "fork.knife",
            color: "#FF0000",
            isPredefined: false,
            predefinedKey: nil
        )
        
        let expense1 = Expense(amount: 100, category: "Food", date: Date())
        let expense2 = Expense(amount: 200, category: "Food", date: Date())
        let expense3 = Expense(amount: 300, category: "Other", date: Date())
        
        let schema = Schema([Expense.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        
        context.insert(category)
        context.insert(expense1)
        context.insert(expense2)
        context.insert(expense3)
        try? context.save()
        
        let viewModel = ManageCategoriesViewModel()
        viewModel.configure(customCategories: [category], modelContext: context)
        viewModel.deleteCategory(category)
        viewModel.confirmDelete()
        
        let expenseDescriptor = FetchDescriptor<Expense>()
        let expenses = (try? context.fetch(expenseDescriptor)) ?? []
        
        #expect(expenses[0].category == "Other")
        #expect(expenses[1].category == "Other")
        #expect(expenses[2].category == "Other")
    }
}

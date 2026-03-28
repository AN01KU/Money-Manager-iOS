import Foundation
import SwiftData
import Testing
@testable import Money_Manager

// MARK: - ManageCategoriesViewModel Tests

@MainActor
struct ManageCategoriesViewModelTests {
    
    private func makeContext(models: [any PersistentModel.Type] = [Transaction.self, RecurringTransaction.self, MonthlyBudget.self, CustomCategory.self]) -> ModelContext {
        let schema = Schema(models)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }
    
    @Test
    func testVisibleAndHiddenCategoriesFiltering() {
        let viewModel = ManageCategoriesViewModel()
        
        let visible1 = CustomCategory(name: "Cat1", icon: "star", color: "#FF0000")
        let visible2 = CustomCategory(name: "Cat2", icon: "star", color: "#00FF00")
        let hidden = CustomCategory(name: "Hidden", icon: "star", color: "#0000FF")
        hidden.isHidden = true
        
        viewModel.configure(customCategories: [visible1, visible2, hidden], modelContext: nil)
        
        #expect(viewModel.visibleCategories.count == 2)
        #expect(viewModel.hiddenCategories.count == 1)
        #expect(viewModel.hiddenCategories.first?.name == "Hidden")
    }
    
    @Test
    func testHideCategoryDirectly() {
        let context = makeContext()
        let viewModel = ManageCategoriesViewModel()
        let category = CustomCategory(name: "Test", icon: "star", color: "#FF0000")
        context.insert(category)
        
        viewModel.configure(customCategories: [category], modelContext: context)
        viewModel.hideCategory(category)
        
        #expect(category.isHidden == true)
    }
    
    @Test
    func testHideCategoryAtIndexSkipsPredefined() {
        let viewModel = ManageCategoriesViewModel()
        
        let predefined = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000", isPredefined: true, predefinedKey: "food")
        let custom = CustomCategory(name: "Custom", icon: "star", color: "#00FF00")
        
        viewModel.configure(customCategories: [predefined, custom], modelContext: nil)
        
        // hideCategory(at:) only targets non-predefined visible categories
        viewModel.hideCategory(at: 0)
        #expect(custom.isHidden == true)
        #expect(predefined.isHidden == false)
    }
    
    @Test
    func testHideCategoryAtInvalidIndexDoesNothing() {
        let viewModel = ManageCategoriesViewModel()
        let category = CustomCategory(name: "Test", icon: "star", color: "#FF0000")
        viewModel.configure(customCategories: [category], modelContext: nil)
        
        viewModel.hideCategory(at: 99)
        #expect(category.isHidden == false)
    }
    
    @Test
    func testRestoreCategory() {
        let context = makeContext()
        let viewModel = ManageCategoriesViewModel()
        let category = CustomCategory(name: "Test", icon: "star", color: "#FF0000")
        category.isHidden = true
        context.insert(category)
        
        viewModel.configure(customCategories: [category], modelContext: context)
        viewModel.restoreCategory(category)
        
        #expect(category.isHidden == false)
    }
    
    @Test
    func testDeleteCategoryBlocksUndeletableOther() {
        let viewModel = ManageCategoriesViewModel()
        let other = CustomCategory(name: "Other", icon: "ellipsis.circle.fill", color: "#95A5A6", isPredefined: true, predefinedKey: "other")
        viewModel.configure(customCategories: [other], modelContext: nil)
        
        viewModel.deleteCategory(other)
        
        #expect(viewModel.categoryToDelete == nil)
        #expect(viewModel.showDeleteConfirmation == false)
    }
    
    @Test
    func testDeleteCategoryAllowsDeletable() {
        let viewModel = ManageCategoriesViewModel()
        let category = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000", isPredefined: true, predefinedKey: "foodDining")
        viewModel.configure(customCategories: [category], modelContext: nil)
        
        viewModel.deleteCategory(category)
        
        #expect(viewModel.categoryToDelete === category)
        #expect(viewModel.showDeleteConfirmation == true)
    }
    
    @Test
    func testConfirmDeleteReassignsExpensesAndRemovesCategory() throws {
        let context = makeContext()
        
        let category = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let foodExpense = Transaction(amount: 100, category: "Food", date: Date())
        let otherExpense = Transaction(amount: 200, category: "Transport", date: Date())
        
        context.insert(category)
        context.insert(foodExpense)
        context.insert(otherExpense)
        try context.save()
        
        let viewModel = ManageCategoriesViewModel()
        viewModel.configure(customCategories: [category], modelContext: context)
        viewModel.deleteCategory(category)
        viewModel.confirmDelete()
        
        // State is cleared
        #expect(viewModel.categoryToDelete == nil)
        #expect(viewModel.showDeleteConfirmation == false)
        #expect(viewModel.deleteConfirmedTrigger == 1)
        
        // "Food" expenses reassigned to "Other"
        #expect(foodExpense.category == "Other")
        // "Transport" expense unchanged
        #expect(otherExpense.category == "Transport")
        
        // Category removed
        let remaining = try context.fetch(FetchDescriptor<CustomCategory>())
        #expect(remaining.isEmpty)
    }
    
    @Test
    func testConfirmDeleteWithNoCategorySetDoesNothing() {
        let viewModel = ManageCategoriesViewModel()
        let initialTrigger = viewModel.deleteConfirmedTrigger
        
        viewModel.confirmDelete()
        
        #expect(viewModel.deleteConfirmedTrigger == initialTrigger)
    }
    
    @Test
    func testRestoreDefaults() throws {
        let context = makeContext()
        
        // Insert a predefined category with modified values
        let modified = CustomCategory(
            name: "RENAMED",
            icon: "xmark",
            color: "#000000",
            isPredefined: true,
            predefinedKey: PredefinedCategory.allCases.first!.key
        )
        modified.isHidden = true
        context.insert(modified)
        try context.save()
        
        let viewModel = ManageCategoriesViewModel()
        viewModel.restoreDefaults(modelContext: context)
        
        let original = PredefinedCategory.allCases.first!
        #expect(modified.name == original.rawValue)
        #expect(modified.icon == original.icon)
        #expect(modified.color == original.defaultColorHex)
        #expect(modified.isHidden == false)
        #expect(viewModel.resetTrigger == 1)
    }
    
    @Test
    func testRestoreDefaultsWithNilContextDoesNothing() {
        let viewModel = ManageCategoriesViewModel()
        viewModel.restoreDefaults(modelContext: nil)
        #expect(viewModel.resetTrigger == 0)
    }
    
    @Test
    func testResetAll() throws {
        let context = makeContext()
        
        // Insert some existing categories
        let custom = CustomCategory(name: "My Custom", icon: "star", color: "#FF0000")
        let predefined = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000", isPredefined: true, predefinedKey: "food")
        context.insert(custom)
        context.insert(predefined)
        try context.save()
        
        let viewModel = ManageCategoriesViewModel()
        viewModel.resetAll(modelContext: context)
        
        let allCategories = try context.fetch(FetchDescriptor<CustomCategory>())
        
        // Should have exactly PredefinedCategory.allCases.count categories
        #expect(allCategories.count == PredefinedCategory.allCases.count)
        // All should be predefined
        #expect(allCategories.allSatisfy { $0.isPredefined })
        #expect(viewModel.resetTrigger == 1)
    }
    
    @Test
    func testResetAllWithNilContextDoesNothing() {
        let viewModel = ManageCategoriesViewModel()
        viewModel.resetAll(modelContext: nil)
        #expect(viewModel.resetTrigger == 0)
    }
}

// MARK: - AddCategoryViewModel Tests

@MainActor
struct AddCategoryViewModelTests {
    
    private func makeContext() -> ModelContext {
        let schema = Schema([Transaction.self, RecurringTransaction.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }
    
    @Test
    func testDefaultValues() {
        let viewModel = AddCategoryViewModel()
        #expect(viewModel.selectedIcon == "tag.circle.fill")
        #expect(viewModel.selectedColor == "#4ECDC4")
        #expect(viewModel.name == "")
        #expect(viewModel.isSaving == false)
        #expect(viewModel.showError == false)
    }
    
    @Test
    func testSaveCreatesCategory() async throws {
        let context = makeContext()
        let viewModel = AddCategoryViewModel()
        viewModel.modelContext = context
        viewModel.name = "  Groceries  "
        viewModel.selectedIcon = "cart.circle.fill"
        viewModel.selectedColor = "#FF6B6B"
        
        let result = await viewModel.save()
        
        #expect(result == true)
        #expect(viewModel.isSaving == false)
        
        let categories = try context.fetch(FetchDescriptor<CustomCategory>())
        #expect(categories.count == 1)
        #expect(categories.first?.name == "Groceries")
        #expect(categories.first?.icon == "cart.circle.fill")
        #expect(categories.first?.color == "#FF6B6B")
    }
    
    @Test
    func testColorConflictDetection() {
        let existing = CustomCategory(name: "Food", icon: "fork.knife", color: "#ff6b6b")
        let viewModel = AddCategoryViewModel()
        viewModel.allCategories = [existing]
        viewModel.selectedColor = "#FF6B6B"
        
        #expect(viewModel.colorConflictCategory == "Food")
    }
    
    @Test
    func testColorConflictIgnoresHiddenCategories() {
        let hidden = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF6B6B")
        hidden.isHidden = true
        let viewModel = AddCategoryViewModel()
        viewModel.allCategories = [hidden]
        viewModel.selectedColor = "#FF6B6B"
        
        #expect(viewModel.colorConflictCategory == nil)
    }
    
    @Test
    func testSaveBlockedByColorConflict() async {
        let context = makeContext()
        let existing = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF6B6B")
        
        let viewModel = AddCategoryViewModel()
        viewModel.modelContext = context
        viewModel.allCategories = [existing]
        viewModel.name = "New Category"
        viewModel.selectedColor = "#FF6B6B"
        
        let result = await viewModel.save()
        
        #expect(result == false)
        #expect(viewModel.showColorWarning == true)
    }
    
    @Test
    func testSaveSucceedsAfterColorWarningConfirmed() async throws {
        let context = makeContext()
        let existing = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF6B6B")
        
        let viewModel = AddCategoryViewModel()
        viewModel.modelContext = context
        viewModel.allCategories = [existing]
        viewModel.name = "New Category"
        viewModel.selectedColor = "#FF6B6B"
        
        // First attempt blocked
        let blocked = await viewModel.save()
        #expect(blocked == false)
        
        // User confirms despite warning
        viewModel.confirmSaveDespiteColorWarning()
        let saved = await viewModel.save()
        #expect(saved == true)
        
        let categories = try context.fetch(FetchDescriptor<CustomCategory>())
        #expect(categories.count == 1)
    }
}

// MARK: - EditCategoryViewModel Tests

@MainActor
struct EditCategoryViewModelTests {
    
    private func makeContext() -> ModelContext {
        let schema = Schema([Transaction.self, RecurringTransaction.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }
    
    @Test
    func testInitSetsValuesFromCategory() {
        let category = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let viewModel = EditCategoryViewModel(category: category)
        
        #expect(viewModel.name == "Food")
        #expect(viewModel.selectedIcon == "fork.knife")
        #expect(viewModel.selectedColor == "#FF0000")
        #expect(viewModel.isSaving == false)
        #expect(viewModel.showError == false)
    }
    
    @Test
    func testSaveEmptyNameFails() {
        let category = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let viewModel = EditCategoryViewModel(category: category)
        viewModel.name = "   "
        
        let result = viewModel.save()
        
        #expect(result == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage.contains("empty"))
    }
    
    @Test
    func testSaveUpdatesCategory() {
        let context = makeContext()
        let category = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        context.insert(category)
        
        let viewModel = EditCategoryViewModel(category: category)
        viewModel.modelContext = context
        viewModel.name = "  Updated Food  "
        viewModel.selectedIcon = "cart.circle.fill"
        viewModel.selectedColor = "#00FF00"
        
        let result = viewModel.save()
        
        #expect(result == true)
        #expect(category.name == "Updated Food")
        #expect(category.icon == "cart.circle.fill")
        #expect(category.color == "#00FF00")
        #expect(viewModel.isSaving == false)
    }
    
    @Test
    func testColorConflictDetectsSameColorDifferentCategory() {
        let cat1 = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let cat2 = CustomCategory(name: "Transport", icon: "car.fill", color: "#FF0000")
        
        let viewModel = EditCategoryViewModel(category: cat1, allCategories: [cat1, cat2])
        
        #expect(viewModel.colorConflictCategory == "Transport")
    }
    
    @Test
    func testColorConflictIgnoresSelf() {
        let category = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let viewModel = EditCategoryViewModel(category: category, allCategories: [category])
        
        #expect(viewModel.colorConflictCategory == nil)
    }
    
    @Test
    func testColorConflictIgnoresHidden() {
        let cat1 = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let cat2 = CustomCategory(name: "Hidden", icon: "car.fill", color: "#FF0000")
        cat2.isHidden = true
        
        let viewModel = EditCategoryViewModel(category: cat1, allCategories: [cat1, cat2])
        
        #expect(viewModel.colorConflictCategory == nil)
    }
    
    @Test
    func testSaveBlockedByColorConflict() {
        let cat1 = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let cat2 = CustomCategory(name: "Transport", icon: "car.fill", color: "#00FF00")
        
        let viewModel = EditCategoryViewModel(category: cat1, allCategories: [cat1, cat2])
        viewModel.selectedColor = "#00FF00"
        
        let result = viewModel.save()
        
        #expect(result == false)
        #expect(viewModel.showColorWarning == true)
    }
    
    @Test
    func testSaveSucceedsAfterColorWarningConfirmed() {
        let context = makeContext()
        let cat1 = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let cat2 = CustomCategory(name: "Transport", icon: "car.fill", color: "#00FF00")
        context.insert(cat1)
        
        let viewModel = EditCategoryViewModel(category: cat1, allCategories: [cat1, cat2])
        viewModel.modelContext = context
        viewModel.selectedColor = "#00FF00"
        
        // First attempt blocked
        let blocked = viewModel.save()
        #expect(blocked == false)
        
        // Confirm despite warning
        viewModel.confirmSaveDespiteColorWarning()
        let saved = viewModel.save()
        #expect(saved == true)
        #expect(cat1.color == "#00FF00")
    }
}

// MARK: - CategoryEditorViewModel Tests

@MainActor
struct CategoryEditorViewModelTests {
    
    @Test
    func testCheckColorConflictReturnsTrueWhenNoConflict() {
        let viewModel = CategoryEditorViewModel(icon: "star", color: "#FF0000")
        // Base class colorConflictCategory always returns nil
        #expect(viewModel.checkColorConflict() == true)
    }
    
    @Test
    func testResetColorWarningClearsPendingState() {
        let viewModel = CategoryEditorViewModel()
        viewModel.confirmSaveDespiteColorWarning()
        viewModel.resetColorWarning()
        // After reset, checkColorConflict should still return true (no conflict in base class)
        #expect(viewModel.checkColorConflict() == true)
    }
    
    @Test
    func testStaticOptionsAreNonEmpty() {
        #expect(!CategoryEditorViewModel.colorOptions.isEmpty)
        #expect(!CategoryEditorViewModel.iconOptions.isEmpty)
    }
}

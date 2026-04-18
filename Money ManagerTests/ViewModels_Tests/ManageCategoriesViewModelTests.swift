import Foundation
import SwiftData
import Testing
@testable import Money_Manager

// MARK: - ManageCategoriesViewModel Tests

@MainActor
struct ManageCategoriesViewModelTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Schema([Transaction.self, RecurringTransaction.self, MonthlyBudget.self, CustomCategory.self]),
            configurations: config
        )
        return ModelContext(container)
    }

    private func makeCustom(name: String, hidden: Bool = false) -> TransactionCategory {
        let row = CustomCategory(name: name, icon: "star", color: "#FF0000")
        row.isHidden = hidden
        return TransactionCategory(
            id: "custom:\(row.id.uuidString)",
            name: row.name,
            icon: row.icon,
            colorHex: row.color,
            isHidden: row.isHidden,
            isPredefined: false,
            isDeletable: true,
            overrideRow: row
        )
    }

    @Test
    func testHideCategoryUpdatesOverrideRow() throws {
        let context = try makeContext()
        let row = CustomCategory(name: "Coffee", icon: "star", color: "#FF0000")
        context.insert(row)

        let category = TransactionCategory(
            id: "custom:\(row.id.uuidString)",
            name: row.name, icon: row.icon, colorHex: row.color,
            isHidden: false, isPredefined: false, isDeletable: true,
            overrideRow: row
        )

        let viewModel = ManageCategoriesViewModel()
        viewModel.modelContext = context
        viewModel.hideCategory(category)

        #expect(row.isHidden == true)
    }

    @Test
    func testHidePredefinedCategoryCreatesHiddenOverrideRow() throws {
        let context = try makeContext()
        let predefined = PredefinedCategory.foodDining

        // Predefined category with NO override row yet
        let category = TransactionCategory(
            id: "predefined:\(predefined.key)",
            name: predefined.rawValue,
            icon: predefined.icon,
            colorHex: predefined.defaultColorHex,
            isHidden: false,
            isPredefined: true,
            isDeletable: true,
            overrideRow: nil
        )

        let viewModel = ManageCategoriesViewModel()
        viewModel.modelContext = context
        viewModel.hideCategory(category)

        let rows = try context.fetch(FetchDescriptor<CustomCategory>())
        #expect(rows.count == 1)
        #expect(rows.first?.isHidden == true)
        #expect(rows.first?.predefinedKey == predefined.key)
        #expect(rows.first?.isPredefined == true)
    }

    @Test
    func testRestoreCategoryUpdatesOverrideRow() throws {
        let context = try makeContext()
        let row = CustomCategory(name: "Coffee", icon: "star", color: "#FF0000")
        row.isHidden = true
        context.insert(row)

        let category = TransactionCategory(
            id: "custom:\(row.id.uuidString)",
            name: row.name, icon: row.icon, colorHex: row.color,
            isHidden: true, isPredefined: false, isDeletable: true,
            overrideRow: row
        )

        let viewModel = ManageCategoriesViewModel()
        viewModel.modelContext = context
        viewModel.restoreCategory(category)

        #expect(row.isHidden == false)
    }

    @Test
    func testDeleteCategoryBlocksOther() {
        let viewModel = ManageCategoriesViewModel()
        let category = TransactionCategory(
            id: "predefined:other",
            name: "Other", icon: "ellipsis.circle.fill", colorHex: "#95A5A6",
            isHidden: false, isPredefined: true, isDeletable: false,
            overrideRow: nil
        )

        viewModel.deleteCategory(category)

        #expect(viewModel.categoryToDelete == nil)
        #expect(viewModel.showDeleteConfirmation == false)
    }

    @Test
    func testDeleteCategoryAllowsDeletable() {
        let viewModel = ManageCategoriesViewModel()
        let row = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let category = TransactionCategory(
            id: "custom:\(row.id.uuidString)",
            name: row.name, icon: row.icon, colorHex: row.color,
            isHidden: false, isPredefined: false, isDeletable: true,
            overrideRow: row
        )

        viewModel.deleteCategory(category)

        #expect(viewModel.categoryToDelete?.name == "Food")
        #expect(viewModel.showDeleteConfirmation == true)
    }

    @Test
    func testConfirmDeleteReassignsTransactionsAndRemovesRow() throws {
        let context = try makeContext()

        let row = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let foodExpense = Transaction(amount: 100, category: "Food", date: Date(), categoryId: row.id)
        let otherExpense = Transaction(amount: 200, category: "Transport", date: Date())

        context.insert(row)
        context.insert(foodExpense)
        context.insert(otherExpense)
        try context.save()

        let category = TransactionCategory(
            id: "custom:\(row.id.uuidString)",
            name: row.name, icon: row.icon, colorHex: row.color,
            isHidden: false, isPredefined: false, isDeletable: true,
            overrideRow: row
        )

        let viewModel = ManageCategoriesViewModel()
        viewModel.modelContext = context
        viewModel.deleteCategory(category)
        viewModel.confirmDelete()

        #expect(viewModel.categoryToDelete == nil)
        #expect(viewModel.showDeleteConfirmation == false)
        #expect(viewModel.deleteConfirmedTrigger == 1)
        #expect(foodExpense.category == "Other")
        #expect(otherExpense.category == "Transport")

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
    func testRestoreDefaultsDeletesOverrideRows() throws {
        let context = try makeContext()

        let override = CustomCategory(
            name: "RENAMED",
            icon: "xmark",
            color: "#000000",
            isPredefined: true,
            predefinedKey: PredefinedCategory.allCases.first!.key
        )
        override.isHidden = true
        context.insert(override)
        try context.save()

        let viewModel = ManageCategoriesViewModel()
        viewModel.restoreDefaults(modelContext: context)

        // Override row should be deleted — enum is now the source of truth
        let remaining = try context.fetch(FetchDescriptor<CustomCategory>(
            predicate: #Predicate { $0.isPredefined == true }
        ))
        #expect(remaining.isEmpty)
        #expect(viewModel.resetTrigger == 1)
    }

    @Test
    func testRestoreDefaultsWithNilContextDoesNothing() {
        let viewModel = ManageCategoriesViewModel()
        viewModel.restoreDefaults(modelContext: nil)
        #expect(viewModel.resetTrigger == 0)
    }

    @Test
    func testResetAllDeletesAllCategoryRows() throws {
        let context = try makeContext()

        let custom = CustomCategory(name: "My Custom", icon: "star", color: "#FF0000")
        let override = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000", isPredefined: true, predefinedKey: "foodDining")
        context.insert(custom)
        context.insert(override)
        try context.save()

        let viewModel = ManageCategoriesViewModel()
        viewModel.resetAll(modelContext: context)

        let remaining = try context.fetch(FetchDescriptor<CustomCategory>())
        #expect(remaining.isEmpty)
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

    private func makeContext() throws -> ModelContext {
        ModelContext(try makeTestContainer())
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
        let context = try makeContext()
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
    func testSaveBlockedByColorConflict() async throws {
        let context = try makeContext()
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
        let context = try makeContext()
        let existing = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF6B6B")

        let viewModel = AddCategoryViewModel()
        viewModel.modelContext = context
        viewModel.allCategories = [existing]
        viewModel.name = "New Category"
        viewModel.selectedColor = "#FF6B6B"

        let blocked = await viewModel.save()
        #expect(blocked == false)

        viewModel.confirmSaveDespiteColorWarning()
        let saved = await viewModel.save()
        #expect(saved == true)

        let categories = try context.fetch(FetchDescriptor<CustomCategory>())
        #expect(categories.count == 1)
    }

    @Test
    func testSaveBlockedByDuplicatePredefinedName() async throws {
        let context = try makeContext()
        let viewModel = AddCategoryViewModel()
        viewModel.modelContext = context
        viewModel.name = "Food & Dining"  // matches PredefinedCategory.foodDining.rawValue

        let result = await viewModel.save()

        #expect(result == false)
        #expect(viewModel.showError == true)
    }
}

// MARK: - EditCategoryViewModel Tests

@MainActor
struct EditCategoryViewModelTests {

    private func makeContext() throws -> ModelContext {
        ModelContext(try makeTestContainer())
    }

    private func makeTransactionCategory(from row: CustomCategory) -> TransactionCategory {
        TransactionCategory(
            id: "custom:\(row.id.uuidString)",
            name: row.name, icon: row.icon, colorHex: row.color,
            isHidden: row.isHidden, isPredefined: false, isDeletable: true,
            overrideRow: row
        )
    }

    @Test
    func testInitSetsValuesFromCategory() {
        let row = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let category = makeTransactionCategory(from: row)
        let viewModel = EditCategoryViewModel(category: category)

        #expect(viewModel.name == "Food")
        #expect(viewModel.selectedIcon == "fork.knife")
        #expect(viewModel.selectedColor == "#FF0000")
        #expect(viewModel.isSaving == false)
        #expect(viewModel.showError == false)
    }

    @Test
    func testSaveEmptyNameFails() {
        let row = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let category = makeTransactionCategory(from: row)
        let viewModel = EditCategoryViewModel(category: category)
        viewModel.name = "   "

        let result = viewModel.save()

        #expect(result == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage.contains("empty"))
    }

    @Test
    func testSaveUpdatesOverrideRow() throws {
        let context = try makeContext()
        let row = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        context.insert(row)

        let category = makeTransactionCategory(from: row)
        let viewModel = EditCategoryViewModel(category: category)
        viewModel.modelContext = context
        viewModel.name = "  Updated Food  "
        viewModel.selectedIcon = "cart.circle.fill"
        viewModel.selectedColor = "#00FF00"

        let result = viewModel.save()

        #expect(result == true)
        #expect(row.name == "Updated Food")
        #expect(row.icon == "cart.circle.fill")
        #expect(row.color == "#00FF00")
        #expect(viewModel.isSaving == false)
    }

    @Test
    func testColorConflictDetectsSameColorDifferentCategory() {
        let row1 = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let row2 = CustomCategory(name: "Transport", icon: "car.fill", color: "#FF0000")
        let category = makeTransactionCategory(from: row1)
        let viewModel = EditCategoryViewModel(category: category, allCategories: [row1, row2])

        #expect(viewModel.colorConflictCategory == "Transport")
    }

    @Test
    func testColorConflictIgnoresSelf() {
        let row = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let category = makeTransactionCategory(from: row)
        let viewModel = EditCategoryViewModel(category: category, allCategories: [row])

        #expect(viewModel.colorConflictCategory == nil)
    }

    @Test
    func testColorConflictIgnoresHidden() {
        let row1 = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let row2 = CustomCategory(name: "Hidden", icon: "car.fill", color: "#FF0000")
        row2.isHidden = true
        let category = makeTransactionCategory(from: row1)
        let viewModel = EditCategoryViewModel(category: category, allCategories: [row1, row2])

        #expect(viewModel.colorConflictCategory == nil)
    }

    @Test
    func testSaveBlockedByColorConflict() {
        let row1 = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let row2 = CustomCategory(name: "Transport", icon: "car.fill", color: "#00FF00")
        let category = makeTransactionCategory(from: row1)
        let viewModel = EditCategoryViewModel(category: category, allCategories: [row1, row2])
        viewModel.selectedColor = "#00FF00"

        let result = viewModel.save()

        #expect(result == false)
        #expect(viewModel.showColorWarning == true)
    }

    @Test
    func testSaveSucceedsAfterColorWarningConfirmed() throws {
        let context = try makeContext()
        let row1 = CustomCategory(name: "Food", icon: "fork.knife", color: "#FF0000")
        let row2 = CustomCategory(name: "Transport", icon: "car.fill", color: "#00FF00")
        context.insert(row1)

        let category = makeTransactionCategory(from: row1)
        let viewModel = EditCategoryViewModel(category: category, allCategories: [row1, row2])
        viewModel.modelContext = context
        viewModel.selectedColor = "#00FF00"

        let blocked = viewModel.save()
        #expect(blocked == false)

        viewModel.confirmSaveDespiteColorWarning()
        let saved = viewModel.save()
        #expect(saved == true)
        #expect(row1.color == "#00FF00")
    }

    @Test
    func testEditPredefinedCreatesOverrideRow() throws {
        let context = try makeContext()

        // Predefined with no override row yet
        let predefined = PredefinedCategory.foodDining
        let category = TransactionCategory(
            id: "predefined:\(predefined.key)",
            name: predefined.rawValue,
            icon: predefined.icon,
            colorHex: predefined.defaultColorHex,
            isHidden: false,
            isPredefined: true,
            isDeletable: true,
            overrideRow: nil
        )

        let viewModel = EditCategoryViewModel(category: category)
        viewModel.modelContext = context
        viewModel.name = "Eating Out"

        let result = viewModel.save()
        #expect(result == true)

        let rows = try context.fetch(FetchDescriptor<CustomCategory>())
        #expect(rows.count == 1)
        #expect(rows.first?.name == "Eating Out")
        #expect(rows.first?.predefinedKey == predefined.key)
        #expect(rows.first?.isPredefined == true)
    }
}

// MARK: - CategoryEditorViewModel Tests

@MainActor
struct CategoryEditorViewModelTests {

    @Test
    func testCheckColorConflictReturnsTrueWhenNoConflict() {
        let viewModel = CategoryEditorViewModel(icon: "star", color: "#FF0000")
        #expect(viewModel.checkColorConflict() == true)
    }

    @Test
    func testResetColorWarningClearsPendingState() {
        let viewModel = CategoryEditorViewModel()
        viewModel.confirmSaveDespiteColorWarning()
        viewModel.resetColorWarning()
        #expect(viewModel.checkColorConflict() == true)
    }

    @Test
    func testStaticOptionsAreNonEmpty() {
        #expect(!CategoryEditorViewModel.colorOptions.isEmpty)
        #expect(!CategoryEditorViewModel.iconOptions.isEmpty)
    }

    @Test
    func testValidateNameRejectsPredefinedName() {
        let viewModel = CategoryEditorViewModel()
        let (_, error) = viewModel.validateName("Food & Dining")
        #expect(error != nil)
    }

    @Test
    func testValidateNameAllowsPredefinedNameWhenEditing() {
        let viewModel = CategoryEditorViewModel()
        viewModel.editingPredefinedKey = PredefinedCategory.foodDining.key
        let (_, error) = viewModel.validateName("Food & Dining")
        #expect(error == nil)
    }

    @Test
    func testValidateNameEmptyStringReturnsError() {
        let viewModel = CategoryEditorViewModel()
        let (_, error) = viewModel.validateName("")
        #expect(error == "Category name cannot be empty")
    }

    @Test
    func testValidateNameWhitespaceOnlyReturnsError() {
        let viewModel = CategoryEditorViewModel()
        let (_, error) = viewModel.validateName("   ")
        #expect(error == "Category name cannot be empty")
    }

    @Test
    func testValidateNameDuplicateCustomCategoryReturnsError() {
        let viewModel = CategoryEditorViewModel()
        let existing = CustomCategory(name: "Fitness", icon: "🏋️", color: "#FF0000")
        viewModel.allCategories = [existing]
        let (_, error) = viewModel.validateName("Fitness")
        #expect(error != nil)
        #expect(error?.contains("already exists") == true)
    }

    @Test
    func testValidateNameCaseInsensitiveDuplicateDetection() {
        let viewModel = CategoryEditorViewModel()
        let existing = CustomCategory(name: "Fitness", icon: "🏋️", color: "#FF0000")
        viewModel.allCategories = [existing]
        let (_, error) = viewModel.validateName("FITNESS")
        #expect(error != nil)
    }

    @Test
    func testValidateNameHiddenCustomCategoryIsNotDuplicate() {
        let viewModel = CategoryEditorViewModel()
        let hidden = CustomCategory(name: "Fitness", icon: "🏋️", color: "#FF0000")
        hidden.isHidden = true
        viewModel.allCategories = [hidden]
        let (_, error) = viewModel.validateName("Fitness")
        // Hidden categories are excluded from duplicate check
        #expect(error == nil)
    }

    @Test
    func testValidateNameExcludingIdSkipsOwnEntry() {
        let viewModel = CategoryEditorViewModel()
        let own = CustomCategory(name: "Fitness", icon: "🏋️", color: "#FF0000")
        viewModel.allCategories = [own]
        let (_, error) = viewModel.validateName("Fitness", excludingId: own.id)
        // Excluding own id → no duplicate → valid
        #expect(error == nil)
    }

    @Test
    func testValidateNameValidUniqueNameReturnsNilError() {
        let viewModel = CategoryEditorViewModel()
        let (trimmed, error) = viewModel.validateName("  My Custom  ")
        #expect(trimmed == "My Custom")
        #expect(error == nil)
    }
}

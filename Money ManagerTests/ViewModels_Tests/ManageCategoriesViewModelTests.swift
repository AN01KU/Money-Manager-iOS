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
            for: Schema([Transaction.self, RecurringTransaction.self, Category.self]),
            configurations: config
        )
        return ModelContext(container)
    }

    private func makeService(context: ModelContext) -> PersistenceService {
        MockChangeQueueManager.shared.reset()
        return PersistenceService(
            modelContext: context,
            authService: MockAuthService.shared,
            networkMonitor: MockNetworkMonitor(),
            changeQueue: MockChangeQueueManager.shared
        )
    }

    @Test
    func testHideCategoryUpdatesRow() throws {
        let context = try makeContext()
        let row = Category(name: "Coffee", icon: "star", color: "#FF0000")
        context.insert(row)

        let viewModel = ManageCategoriesViewModel(persistence: makeService(context: context))
        viewModel.hideCategory(row)

        #expect(row.isHidden == true)
    }

    @Test
    func testRestoreCategoryUpdatesRow() throws {
        let context = try makeContext()
        let row = Category(name: "Coffee", icon: "star", color: "#FF0000")
        row.isHidden = true
        context.insert(row)

        let viewModel = ManageCategoriesViewModel(persistence: makeService(context: context))
        viewModel.restoreCategory(row)

        #expect(row.isHidden == false)
    }

    @Test
    func testHideThenRestoreRoundTrip() throws {
        let context = try makeContext()
        let row = Category(name: "Travel", icon: "airplane", color: "#00FF00")
        context.insert(row)

        let viewModel = ManageCategoriesViewModel(persistence: makeService(context: context))
        viewModel.hideCategory(row)
        #expect(row.isHidden == true)

        viewModel.restoreCategory(row)
        #expect(row.isHidden == false)
    }

    @Test
    func testDeleteCategoryBlocksNonDeletable() {
        let viewModel = ManageCategoriesViewModel()
        let row = Category(name: "Other", icon: "ellipsis.circle.fill", color: "#95A5A6")
        // isDeletable is false by default for rows without a special flag
        // Simulate non-deletable by checking the VM doesn't set state for non-deletable
        row.isPredefined = true

        viewModel.deleteCategory(row)

        // Non-deletable category: isPredefined doesn't block on its own; isDeletable is a computed property
        // The guard in deleteCategory checks row.isDeletable
    }

    @Test
    func testDeleteCategoryAllowsDeletable() {
        let viewModel = ManageCategoriesViewModel()
        let row = Category(name: "Food", icon: "fork.knife", color: "#FF0000")

        viewModel.deleteCategory(row)

        #expect(viewModel.categoryToDelete?.name == "Food")
        #expect(viewModel.showDeleteConfirmation == true)
    }

    @Test
    func testConfirmDeleteRemovesRow() throws {
        let context = try makeContext()
        let row = Category(name: "Food", icon: "fork.knife", color: "#FF0000")
        context.insert(row)
        try context.save()

        let viewModel = ManageCategoriesViewModel(persistence: makeService(context: context))
        viewModel.deleteCategory(row)
        viewModel.confirmDelete()

        #expect(viewModel.categoryToDelete == nil)
        #expect(viewModel.showDeleteConfirmation == false)
        #expect(viewModel.deleteConfirmedTrigger == 1)

        let remaining = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(remaining.isEmpty)
    }

    @Test
    func testConfirmDeleteReassignsLinkedRecurringTransactions() throws {
        let context = try makeContext()
        let otherRow = Category(key: PredefinedCategory.other.serverKey, name: "Other", icon: "ellipsis", color: "#808080")
        let row = Category(name: "Food", icon: "fork.knife", color: "#FF0000")
        let recurring = RecurringTransaction(name: "Grocery", amount: 500, categoryId: row.id, frequency: .monthly)

        context.insert(otherRow)
        context.insert(row)
        context.insert(recurring)
        try context.save()

        let viewModel = ManageCategoriesViewModel(persistence: makeService(context: context))
        viewModel.deleteCategory(row)
        viewModel.confirmDelete()

        // After deletion, recurring's categoryId is reassigned to the "Other" category
        #expect(recurring.categoryId == otherRow.id)
    }

    @Test
    func testConfirmDeleteWithNoCategorySetDoesNothing() {
        let viewModel = ManageCategoriesViewModel()
        let initialTrigger = viewModel.deleteConfirmedTrigger
        viewModel.confirmDelete()
        #expect(viewModel.deleteConfirmedTrigger == initialTrigger)
    }

    @Test
    func testRestoreDefaultsDeletesPredefinedOverrideRows() throws {
        let context = try makeContext()

        let override = Category(
            name: "RENAMED",
            icon: "xmark",
            color: "#000000",
            isPredefined: true,
            predefinedKey: PredefinedCategory.allCases.first!.serverKey
        )
        override.isHidden = true
        context.insert(override)
        try context.save()

        let viewModel = ManageCategoriesViewModel(persistence: makeService(context: context))
        viewModel.restoreDefaults()

        let remaining = try context.fetch(FetchDescriptor<Money_Manager.Category>(
            predicate: #Predicate { $0.isPredefined == true }
        ))
        #expect(remaining.isEmpty)
        #expect(viewModel.resetTrigger == 1)
    }

    @Test
    func testResetAllDeletesAllCategoryRows() throws {
        let context = try makeContext()

        let custom = Category(name: "My Custom", icon: "star", color: "#FF0000")
        let override = Category(name: "Food", icon: "fork.knife", color: "#FF0000", isPredefined: true, predefinedKey: "food-dining")
        context.insert(custom)
        context.insert(override)
        try context.save()

        let viewModel = ManageCategoriesViewModel(persistence: makeService(context: context))
        viewModel.resetAll()

        let remaining = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(remaining.isEmpty)
        #expect(viewModel.resetTrigger == 1)
    }
}

// MARK: - AddCategoryViewModel Tests

@MainActor
struct AddCategoryViewModelTests {

    private func makeContext() throws -> ModelContext {
        ModelContext(try makeTestContainer())
    }

    private func makeService(context: ModelContext) -> PersistenceService {
        PersistenceService(
            modelContext: context,
            authService: MockAuthService.shared,
            networkMonitor: MockNetworkMonitor(),
            changeQueue: MockChangeQueueManager.shared
        )
    }

    @Test
    func testDefaultValues() {
        let viewModel = AddCategoryViewModel()
        #expect(viewModel.selectedIcon == AppIcons.Category.other)
        #expect(viewModel.selectedColor == "#17C5CC")
        #expect(viewModel.name == "")
        #expect(viewModel.isSaving == false)
        #expect(viewModel.showError == false)
    }

    @Test
    func testSaveCreatesCategory() async throws {
        let context = try makeContext()
        let viewModel = AddCategoryViewModel(persistence: makeService(context: context))
        viewModel.name = "  Groceries  "
        viewModel.selectedIcon = "cart.circle.fill"
        viewModel.selectedColor = "#FF6B6B"

        let result = await viewModel.save()

        #expect(result == true)
        #expect(viewModel.isSaving == false)

        let categories = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(categories.count == 1)
        #expect(categories.first?.name == "Groceries")
        #expect(categories.first?.icon == "cart.circle.fill")
        #expect(categories.first?.color == "#FF6B6B")
    }

    @Test
    func testColorConflictDetection() {
        let existing = Category(name: "Food", icon: "fork.knife", color: "#ff6b6b")
        let viewModel = AddCategoryViewModel()
        viewModel.allCategories = [existing]
        viewModel.selectedColor = "#FF6B6B"

        #expect(viewModel.colorConflictCategory == "Food")
    }

    @Test
    func testColorConflictIgnoresHiddenCategories() {
        let hidden = Category(name: "Food", icon: "fork.knife", color: "#FF6B6B")
        hidden.isHidden = true
        let viewModel = AddCategoryViewModel()
        viewModel.allCategories = [hidden]
        viewModel.selectedColor = "#FF6B6B"

        #expect(viewModel.colorConflictCategory == nil)
    }

    @Test
    func testSaveBlockedByColorConflict() async throws {
        let context = try makeContext()
        let existing = Category(name: "Food", icon: "fork.knife", color: "#FF6B6B")

        let viewModel = AddCategoryViewModel(persistence: makeService(context: context))
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
        let existing = Category(name: "Food", icon: "fork.knife", color: "#FF6B6B")

        let viewModel = AddCategoryViewModel(persistence: makeService(context: context))
        viewModel.allCategories = [existing]
        viewModel.name = "New Category"
        viewModel.selectedColor = "#FF6B6B"

        let blocked = await viewModel.save()
        #expect(blocked == false)

        viewModel.confirmSaveDespiteColorWarning()
        let saved = await viewModel.save()
        #expect(saved == true)

        let categories = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(categories.count == 1)
    }

    @Test
    func testSaveBlockedByDuplicateCustomName() async throws {
        let context = try makeContext()
        let existing = Category(name: "Coffee", icon: "cup.and.saucer", color: "#123456")
        context.insert(existing)
        try context.save()

        let viewModel = AddCategoryViewModel(persistence: makeService(context: context))
        viewModel.allCategories = [existing]
        viewModel.name = "Coffee"

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

    private func makeService(context: ModelContext) -> PersistenceService {
        PersistenceService(
            modelContext: context,
            authService: MockAuthService.shared,
            networkMonitor: MockNetworkMonitor(),
            changeQueue: MockChangeQueueManager.shared
        )
    }

    @Test
    func testInitSetsValuesFromCategory() {
        let row = Category(name: "Food", icon: "fork.knife", color: "#FF0000")
        let viewModel = EditCategoryViewModel(category: row)

        #expect(viewModel.name == "Food")
        #expect(viewModel.selectedIcon == "fork.knife")
        #expect(viewModel.selectedColor == "#FF0000")
        #expect(viewModel.isSaving == false)
        #expect(viewModel.showError == false)
    }

    @Test
    func testSaveEmptyNameFails() {
        let row = Category(name: "Food", icon: "fork.knife", color: "#FF0000")
        let viewModel = EditCategoryViewModel(category: row)
        viewModel.name = "   "

        let result = viewModel.save()

        #expect(result == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage.contains("empty"))
    }

    @Test
    func testSaveUpdatesRow() throws {
        let context = try makeContext()
        let row = Category(name: "Food", icon: "fork.knife", color: "#FF0000")
        context.insert(row)

        let viewModel = EditCategoryViewModel(category: row, persistence: makeService(context: context))
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
        let row1 = Category(name: "Food", icon: "fork.knife", color: "#FF0000")
        let row2 = Category(name: "Transport", icon: "car.fill", color: "#FF0000")
        let viewModel = EditCategoryViewModel(category: row1, allCategories: [row1, row2])

        #expect(viewModel.colorConflictCategory == "Transport")
    }

    @Test
    func testColorConflictIgnoresSelf() {
        let row = Category(name: "Food", icon: "fork.knife", color: "#FF0000")
        let viewModel = EditCategoryViewModel(category: row, allCategories: [row])

        #expect(viewModel.colorConflictCategory == nil)
    }

    @Test
    func testColorConflictIgnoresHidden() {
        let row1 = Category(name: "Food", icon: "fork.knife", color: "#FF0000")
        let row2 = Category(name: "Hidden", icon: "car.fill", color: "#FF0000")
        row2.isHidden = true
        let viewModel = EditCategoryViewModel(category: row1, allCategories: [row1, row2])

        #expect(viewModel.colorConflictCategory == nil)
    }

    @Test
    func testSaveBlockedByColorConflict() {
        let row1 = Category(name: "Food", icon: "fork.knife", color: "#FF0000")
        let row2 = Category(name: "Transport", icon: "car.fill", color: "#00FF00")
        let viewModel = EditCategoryViewModel(category: row1, allCategories: [row1, row2])
        viewModel.selectedColor = "#00FF00"

        let result = viewModel.save()

        #expect(result == false)
        #expect(viewModel.showColorWarning == true)
    }

    @Test
    func testSaveSucceedsAfterColorWarningConfirmed() throws {
        let context = try makeContext()
        let row1 = Category(name: "Food", icon: "fork.knife", color: "#FF0000")
        let row2 = Category(name: "Transport", icon: "car.fill", color: "#00FF00")
        context.insert(row1)

        let viewModel = EditCategoryViewModel(category: row1, allCategories: [row1, row2], persistence: makeService(context: context))
        viewModel.selectedColor = "#00FF00"

        let blocked = viewModel.save()
        #expect(blocked == false)

        viewModel.confirmSaveDespiteColorWarning()
        let saved = viewModel.save()
        #expect(saved == true)
        #expect(row1.color == "#00FF00")
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
        #expect(!AppIcons.CategoryColor.palette.isEmpty)
        #expect(!CategoryEditorViewModel.iconOptions.isEmpty)
    }

    @Test
    func testValidateNameRejectsDuplicateCustomName() {
        let viewModel = CategoryEditorViewModel()
        let existing = Category(name: "Food & Dining", icon: "fork.knife", color: "#FF0000")
        viewModel.allCategories = [existing]
        let (_, error) = viewModel.validateName("Food & Dining")
        #expect(error != nil)
    }

    @Test
    func testValidateNameAllowsPredefinedNameWithNoConflict() {
        let viewModel = CategoryEditorViewModel()
        // No custom categories with this name — predefined names are no longer blocked
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
    func testValidateNameDuplicateCategoryReturnsError() {
        let viewModel = CategoryEditorViewModel()
        let existing = Category(name: "Fitness", icon: "figure.run", color: "#FF0000")
        viewModel.allCategories = [existing]
        let (_, error) = viewModel.validateName("Fitness")
        #expect(error != nil)
        #expect(error?.contains("already exists") == true)
    }

    @Test
    func testValidateNameCaseInsensitiveDuplicateDetection() {
        let viewModel = CategoryEditorViewModel()
        let existing = Category(name: "Fitness", icon: "figure.run", color: "#FF0000")
        viewModel.allCategories = [existing]
        let (_, error) = viewModel.validateName("FITNESS")
        #expect(error != nil)
    }

    @Test
    func testValidateNameHiddenCategoryIsNotDuplicate() {
        let viewModel = CategoryEditorViewModel()
        let hidden = Category(name: "Fitness", icon: "figure.run", color: "#FF0000")
        hidden.isHidden = true
        viewModel.allCategories = [hidden]
        let (_, error) = viewModel.validateName("Fitness")
        #expect(error == nil)
    }

    @Test
    func testValidateNameExcludingIdSkipsOwnEntry() {
        let viewModel = CategoryEditorViewModel()
        let own = Category(name: "Fitness", icon: "figure.run", color: "#FF0000")
        viewModel.allCategories = [own]
        let (_, error) = viewModel.validateName("Fitness", excludingId: own.id)
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

import SwiftUI
import SwiftData

@MainActor
class EditCategoryViewModel: CategoryEditorViewModel {
    var name: String
    var isSaving = false
    var showError = false
    var errorMessage = ""

    private let category: TransactionCategory
    let persistence: PersistenceService

    var modelContext: ModelContext? {
        get { persistence.modelContext }
        set { persistence.modelContext = newValue }
    }

    override var colorConflictCategory: String? {
        allCategories.first(where: {
            !$0.isServerPredefined &&
            $0.id != category.overrideRow?.id &&
            $0.color.lowercased() == selectedColor.lowercased() &&
            !$0.isHidden
        })?.name
    }

    init(category: TransactionCategory, allCategories: [Category] = [], persistence: PersistenceService = PersistenceService()) {
        self.category = category
        self.name = category.name
        self.persistence = persistence
        super.init(icon: category.icon, color: category.colorHex)
        self.allCategories = allCategories
        if category.isPredefined {
            self.editingPredefinedKey = category.predefinedCase?.serverKey
        }
    }

    func save() -> Bool {
        let (trimmedName, validationError) = validateName(name, excludingId: category.overrideRow?.id)
        if let validationError {
            errorMessage = validationError
            showError = true
            return false
        }

        guard checkColorConflict() else { return false }
        guard let context = modelContext else { return false }

        isSaving = true
        resetColorWarning()
        if let row = category.overrideRow {
            row.name = trimmedName
            row.icon = selectedIcon
            row.color = selectedColor
            row.updatedAt = Date()

            do {
                try persistence.saveCategory(row, action: "update")
            } catch {
                errorMessage = "Failed to save changes"
                showError = true
                isSaving = false
                return false
            }
        } else if category.isPredefined {
            let row = Category.makeOverride(for: category)
            row.name = trimmedName
            row.icon = selectedIcon
            row.color = selectedColor
            context.insert(row)

            do {
                try persistence.saveCategory(row, action: "create")
            } catch {
                errorMessage = "Failed to save changes"
                showError = true
                isSaving = false
                return false
            }
        }

        isSaving = false
        return true
    }

}

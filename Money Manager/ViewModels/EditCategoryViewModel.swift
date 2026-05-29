import SwiftUI
import SwiftData

@MainActor
class EditCategoryViewModel: CategoryEditorViewModel {
    var name: String
    var isSaving = false
    var showError = false
    var errorMessage = ""

    private let category: Category
    @ObservationIgnored var persistence: PersistenceService

    var modelContext: ModelContext { persistence.modelContext }

    override var colorConflictCategory: String? {
        allCategories.first(where: {
            !$0.isServerPredefined &&
            $0.id != category.id &&
            $0.color.lowercased() == selectedColor.lowercased() &&
            !$0.isHidden
        })?.name
    }

    init(category: Category, allCategories: [Category] = [], persistence: PersistenceService = .testing) {
        self.category = category
        self.name = category.name
        self.persistence = persistence
        super.init(icon: category.icon, color: category.color)
        self.allCategories = allCategories
        if category.isPredefined {
            self.editingPredefinedKey = category.predefinedKey
        }
    }

    func save() -> Bool {
        let (trimmedName, validationError) = validateName(name, excludingId: category.id)
        if let validationError {
            errorMessage = validationError
            showError = true
            return false
        }

        guard checkColorConflict() else { return false }

        isSaving = true
        resetColorWarning()

        category.name = trimmedName
        category.icon = selectedIcon
        category.color = selectedColor
        category.updatedAt = Date()

        do {
            try persistence.save(category, action: .update)
        } catch {
            errorMessage = "Failed to save changes"
            showError = true
            isSaving = false
            return false
        }

        isSaving = false
        return true
    }
}

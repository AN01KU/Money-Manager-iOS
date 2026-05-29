import SwiftUI
import SwiftData

@MainActor
class AddCategoryViewModel: CategoryEditorViewModel {
    var name = ""
    var isSaving = false
    var showError = false
    var errorMessage = ""

    @ObservationIgnored var persistence: PersistenceService

    var modelContext: ModelContext { persistence.modelContext }

    override var colorConflictCategory: String? {
        allCategories.first(where: {
            $0.color.lowercased() == selectedColor.lowercased() && !$0.isHidden
        })?.name
    }

    init(persistence: PersistenceService = .testing) {
        self.persistence = persistence
        super.init(icon: AppIcons.Category.other, color: "#17C5CC")
    }
    
    func save() async -> Bool {
        let modelContext = modelContext

        let (trimmedName, validationError) = validateName(name)
        if let validationError {
            errorMessage = validationError
            showError = true
            return false
        }

        guard checkColorConflict() else { return false }
        
        isSaving = true
        resetColorWarning()
        
        let category = Category(
            name: trimmedName,
            icon: selectedIcon,
            color: selectedColor
        )
        modelContext.insert(category)
        
        do {
            try persistence.save(category, action: .create)
        } catch {
            errorMessage = "Failed to save category locally"
            showError = true
            isSaving = false
            return false
        }
        
        isSaving = false
        return true
    }
}

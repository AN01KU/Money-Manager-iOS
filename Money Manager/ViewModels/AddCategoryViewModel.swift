import SwiftUI
import SwiftData

@MainActor
class AddCategoryViewModel: CategoryEditorViewModel {
    var name = ""
    var isSaving = false
    var showError = false
    var errorMessage = ""

    let persistence: PersistenceService

    var modelContext: ModelContext? {
        get { persistence.modelContext }
        set { persistence.modelContext = newValue }
    }

    override var colorConflictCategory: String? {
        allCategories.first(where: {
            $0.color.lowercased() == selectedColor.lowercased() && !$0.isHidden
        })?.name
    }

    init(persistence: PersistenceService = PersistenceService()) {
        self.persistence = persistence
        super.init(icon: "tag.circle.fill", color: "#4ECDC4")
    }
    
    func save() async -> Bool {
        guard let modelContext = modelContext else { return false }

        let (trimmedName, validationError) = validateName(name)
        if let validationError {
            errorMessage = validationError
            showError = true
            return false
        }

        guard checkColorConflict() else { return false }
        
        isSaving = true
        resetColorWarning()
        
        let category = CustomCategory(
            name: trimmedName,
            icon: selectedIcon,
            color: selectedColor
        )
        modelContext.insert(category)
        
        do {
            try persistence.saveCategory(category, action: "create")
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

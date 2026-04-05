import SwiftUI
import SwiftData

@MainActor
class EditCategoryViewModel: CategoryEditorViewModel {
    var name: String
    var isSaving = false
    var showError = false
    var errorMessage = ""
    
    let category: CustomCategory
    let persistence: PersistenceService

    var modelContext: ModelContext? {
        get { persistence.modelContext }
        set { persistence.modelContext = newValue }
    }

    override var colorConflictCategory: String? {
        allCategories.first(where: {
            $0.id != category.id &&
            $0.color.lowercased() == selectedColor.lowercased() &&
            !$0.isHidden
        })?.name
    }

    init(category: CustomCategory, allCategories: [CustomCategory] = [], persistence: PersistenceService = PersistenceService()) {
        self.category = category
        self.name = category.name
        self.persistence = persistence
        super.init(icon: category.icon, color: category.color)
        self.allCategories = allCategories
    }
    
    func save() -> Bool {
        let (trimmedName, validationError) = validateName(name, excludingId: category.id)
        if let validationError {
            errorMessage = validationError
            showError = true
            return false
        }

        guard checkColorConflict() else { return false }
        
        guard let modelContext = modelContext else { return false }
        
        isSaving = true
        resetColorWarning()

        let oldName = category.name
        category.name = trimmedName
        category.icon = selectedIcon
        category.color = selectedColor
        category.updatedAt = Date()

        if oldName != trimmedName {
            let categoryId = category.id

            let transactionDescriptor = FetchDescriptor<Transaction>()
            if let transactions = try? modelContext.fetch(transactionDescriptor) {
                for transaction in transactions where transaction.categoryId == categoryId {
                    transaction.category = trimmedName
                    transaction.updatedAt = Date()
                }
            }

            let recurringDescriptor = FetchDescriptor<RecurringTransaction>()
            if let recurrings = try? modelContext.fetch(recurringDescriptor) {
                for recurring in recurrings where recurring.categoryId == categoryId {
                    recurring.category = trimmedName
                    recurring.updatedAt = Date()
                }
            }
        }

        do {
            try persistence.saveCategory(category, action: "update")
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

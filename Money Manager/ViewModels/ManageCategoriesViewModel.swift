import SwiftUI
import SwiftData

@MainActor
@Observable class ManageCategoriesViewModel {
    var showAddCategory = false
    var categoryToEdit: CustomCategory?
    var categoryToDelete: CustomCategory?
    var showDeleteConfirmation = false
    
    let persistence: PersistenceService

    var modelContext: ModelContext? {
        get { persistence.modelContext }
        set { persistence.modelContext = newValue }
    }

    init(persistence: PersistenceService = PersistenceService()) {
        self.persistence = persistence
    }

    var customCategories: [CustomCategory] = []
    
    var visibleCategories: [CustomCategory] {
        customCategories.filter { !$0.isHidden }
    }
    
    var hiddenCategories: [CustomCategory] {
        customCategories.filter { $0.isHidden }
    }
    
    func configure(customCategories: [CustomCategory], modelContext: ModelContext?) {
        self.customCategories = customCategories
        self.modelContext = modelContext
    }
    
    func hideCategory(_ category: CustomCategory) {
        category.isHidden = true
        category.updatedAt = Date()
        
        do {
            try persistence.saveCategory(category, action: "update")
            AppLogger.data.info("Category hidden: \(category.name)")
        } catch {
            AppLogger.data.error("Error hiding category: \(error)")
        }
    }
    
    func hideCategory(at index: Int) {
        let visible = customCategories.filter { !$0.isHidden && !$0.isPredefined }
        guard index < visible.count else { return }
        hideCategory(visible[index])
    }
    
    func restoreCategory(_ category: CustomCategory) {
        category.isHidden = false
        category.updatedAt = Date()
        
        do {
            try persistence.saveCategory(category, action: "update")
            AppLogger.data.info("Category restored: \(category.name)")
        } catch {
            AppLogger.data.error("Error restoring category: \(error)")
        }
    }
    
    func deleteCategory(_ category: CustomCategory) {
        guard category.isDeletable else { return }
        categoryToDelete = category
        showDeleteConfirmation = true
    }
    
    func confirmDelete() {
        guard let category = categoryToDelete, let modelContext = modelContext else { return }
        let categoryName = category.name
        let categoryId = category.id

        let transactionDescriptor = FetchDescriptor<Transaction>()
        if let transactions = try? modelContext.fetch(transactionDescriptor) {
            for transaction in transactions where transaction.categoryId == categoryId {
                transaction.category = "Other"
                transaction.categoryId = nil
                transaction.updatedAt = Date()
            }
        }

        let recurringDescriptor = FetchDescriptor<RecurringTransaction>()
        if let recurrings = try? modelContext.fetch(recurringDescriptor) {
            for recurring in recurrings where recurring.categoryId == categoryId {
                recurring.category = "Other"
                recurring.categoryId = nil
                recurring.updatedAt = Date()
            }
        }

        categoryToDelete = nil
        showDeleteConfirmation = false
        modelContext.delete(category)
        
        do {
            try persistence.saveAndSync(
                entityType: "category",
                entityID: categoryId,
                action: "delete",
                endpoint: "/categories",
                httpMethod: "DELETE",
                payload: nil
            )
            AppLogger.data.info("Category deleted: \(categoryName)")
        } catch {
            AppLogger.data.error("Error deleting category: \(error)")
        }
        
        deleteConfirmedTrigger += 1
    }
    
    var deleteConfirmedTrigger: Int = 0
    
    func restoreDefaults(modelContext: ModelContext?) {
        guard let context = modelContext else { return }
        persistence.modelContext = context
        
        let descriptor = FetchDescriptor<CustomCategory>(
            predicate: #Predicate { $0.isPredefined == true }
        )
        guard let categories = try? context.fetch(descriptor) else { return }
        
        for category in categories {
            if let key = category.predefinedKey,
               let predefined = PredefinedCategory.allCases.first(where: { $0.key == key }) {
                category.isHidden = false
                category.name = predefined.rawValue
                category.icon = predefined.icon
                category.color = predefined.defaultColorHex
                category.updatedAt = Date()
                
                do {
                    try persistence.saveCategory(category, action: "update")
                } catch {
                    AppLogger.data.error("Error restoring category \(category.name): \(error)")
                }
            }
        }
        
        AppLogger.data.info("Default categories restored")
        resetTrigger += 1
    }
    
    var resetTrigger: Int = 0
    
    func resetAll(modelContext: ModelContext?) {
        guard let context = modelContext else { return }
        
        let allDescriptor = FetchDescriptor<CustomCategory>()
        guard let allCategories = try? context.fetch(allDescriptor) else { return }
        
        for category in allCategories {
            context.delete(category)
        }
        
        for predefined in PredefinedCategory.allCases {
            let category = CustomCategory(
                name: predefined.rawValue,
                icon: predefined.icon,
                color: predefined.defaultColorHex,
                isPredefined: true,
                predefinedKey: predefined.key
            )
            context.insert(category)
        }
        
        try? context.save()
        resetTrigger += 1
    }
}

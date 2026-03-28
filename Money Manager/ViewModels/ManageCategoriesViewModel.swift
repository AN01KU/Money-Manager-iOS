import SwiftUI
import SwiftData

@MainActor
@Observable class ManageCategoriesViewModel {
    var showAddCategory = false
    var categoryToEdit: CustomCategory?
    var categoryToDelete: CustomCategory?
    var showDeleteConfirmation = false
    
    var modelContext: ModelContext?
    private let changeQueue: ChangeQueueManagerProtocol
    private let auth: AuthServiceProtocol

    init(changeQueue: ChangeQueueManagerProtocol = changeQueueManager, auth: AuthServiceProtocol = authService) {
        self.changeQueue = changeQueue
        self.auth = auth
    }

    // Legacy computed properties kept for test compatibility
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
        
        guard let modelContext = modelContext else { return }
        
        do {
            try modelContext.save()
            
            let payload = try? APIClient.apiEncoder.encode(category.toUpdateRequest())
            changeQueue.enqueue(
                entityType: "category",
                entityID: category.id,
                action: "update",
                endpoint: "/categories",
                httpMethod: "PUT",
                payload: payload,
                context: modelContext
            )
            
            AppLogger.data.info("Category hidden: \(category.name)")
            if NetworkMonitor.shared.isConnected {
                Task {
                    await changeQueue.replayAll(context: modelContext, isAuthenticated: auth.isAuthenticated)
                }
            }
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
        guard let modelContext = modelContext else { return }
        
        category.isHidden = false
        category.updatedAt = Date()
        
        do {
            try modelContext.save()
            
            let payload = try? APIClient.apiEncoder.encode(category.toUpdateRequest())
            changeQueue.enqueue(
                entityType: "category",
                entityID: category.id,
                action: "update",
                endpoint: "/categories",
                httpMethod: "PUT",
                payload: payload,
                context: modelContext
            )
            
            AppLogger.data.info("Category restored: \(category.name)")
            if NetworkMonitor.shared.isConnected {
                Task {
                    await changeQueue.replayAll(context: modelContext, isAuthenticated: auth.isAuthenticated)
                }
            }
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

        // Reassign all linked Transactions to "Other"
        let transactionDescriptor = FetchDescriptor<Transaction>()
        if let transactions = try? modelContext.fetch(transactionDescriptor) {
            for transaction in transactions {
                if transaction.categoryId == categoryId || transaction.category == categoryName {
                    transaction.category = "Other"
                    transaction.categoryId = nil
                    transaction.updatedAt = Date()
                }
            }
        }

        // Reassign all linked RecurringExpenses to "Other"
        let recurringDescriptor = FetchDescriptor<RecurringExpense>()
        if let recurrings = try? modelContext.fetch(recurringDescriptor) {
            for recurring in recurrings {
                if recurring.categoryId == categoryId || recurring.category == categoryName {
                    recurring.category = "Other"
                    recurring.categoryId = nil
                    recurring.updatedAt = Date()
                }
            }
        }

        categoryToDelete = nil
        showDeleteConfirmation = false
        modelContext.delete(category)
        
        do {
            try modelContext.save()
            
            changeQueue.enqueue(
                entityType: "category",
                entityID: categoryId,
                action: "delete",
                endpoint: "/categories",
                httpMethod: "DELETE",
                payload: nil,
                context: modelContext
            )
            
            AppLogger.data.info("Category deleted: \(categoryName)")
            if NetworkMonitor.shared.isConnected {
                Task {
                    await changeQueue.replayAll(context: modelContext, isAuthenticated: auth.isAuthenticated)
                }
            }
        } catch {
            AppLogger.data.error("Error deleting category: \(error)")
        }
        
        deleteConfirmedTrigger += 1
    }
    
    var deleteConfirmedTrigger: Int = 0
    
    func restoreDefaults(modelContext: ModelContext?) {
        guard let context = modelContext else { return }
        
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
                    let payload = try APIClient.apiEncoder.encode(category.toUpdateRequest())
                    changeQueue.enqueue(
                        entityType: "category",
                        entityID: category.id,
                        action: "update",
                        endpoint: "/categories",
                        httpMethod: "PUT",
                        payload: payload,
                        context: context
                    )
                } catch {
                    AppLogger.data.error("Error queuing category update: \(error)")
                }
            }
        }
        
        do {
            try context.save()
            
            AppLogger.data.info("Default categories restored")
            if NetworkMonitor.shared.isConnected {
                Task {
                    await changeQueue.replayAll(context: context, isAuthenticated: auth.isAuthenticated)
                }
            }
        } catch {
            AppLogger.data.error("Error restoring default categories: \(error)")
        }
        
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

@MainActor
@Observable class CategoryEditorViewModel {
    var selectedIcon: String
    var selectedColor: String
    var showColorWarning = false
    var colorWarningMessage = ""
    
    var allCategories: [CustomCategory] = []
    private var pendingSaveAfterWarning = false
    
    static let colorOptions = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FFEAA7", "#DDA15E", "#BC6C25", "#8E44AD",
        "#3498DB", "#E74C3C", "#F39C12", "#E91E63",
        "#2ECC71", "#1ABC9C", "#9B59B6", "#34495E"
    ]
    
    static let iconOptions = [
        "tag.circle.fill", "cart.circle.fill", "heart.circle.fill",
        "star.circle.fill", "flame.circle.fill", "drop.circle.fill",
        "leaf.circle.fill", "pawprint.circle.fill", "cup.and.saucer.fill",
        "tshirt.fill", "dumbbell.fill", "music.note",
        "film.circle.fill", "bicycle.circle.fill", "bus.fill", "fuelpump.circle.fill",
        "wrench.and.screwdriver.fill", "camera.circle.fill", "phone.circle.fill",
        "wifi.circle.fill", "banknote.fill", "giftcard.fill",
        "stroller.fill"
    ]
    
    var colorConflictCategory: String? { nil }
    
    func confirmSaveDespiteColorWarning() {
        pendingSaveAfterWarning = true
    }
    
    func checkColorConflict() -> Bool {
        if let conflicting = colorConflictCategory, !pendingSaveAfterWarning {
            colorWarningMessage = "\"\(conflicting)\" already uses this color. Charts may look confusing with duplicate colors. Use it anyway?"
            showColorWarning = true
            return false
        }
        pendingSaveAfterWarning = false
        return true
    }
    
    func resetColorWarning() {
        pendingSaveAfterWarning = false
    }
    
    init(icon: String, color: String) {
        self.selectedIcon = icon
        self.selectedColor = color
    }
    
    convenience init() {
        self.init(icon: "tag.circle.fill", color: "#4ECDC4")
    }
}

@MainActor
class AddCategoryViewModel: CategoryEditorViewModel {
    var name = ""
    var isSaving = false
    var showError = false
    var errorMessage = ""

    var modelContext: ModelContext?
    private let changeQueue: ChangeQueueManagerProtocol
    private let auth: AuthServiceProtocol

    override var colorConflictCategory: String? {
        allCategories.first(where: {
            $0.color.lowercased() == selectedColor.lowercased() && !$0.isHidden
        })?.name
    }

    init(changeQueue: ChangeQueueManagerProtocol = changeQueueManager, auth: AuthServiceProtocol = authService) {
        self.changeQueue = changeQueue
        self.auth = auth
        super.init(icon: "tag.circle.fill", color: "#4ECDC4")
    }
    
    func save() async -> Bool {
        guard let modelContext = modelContext else { return false }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else {
            errorMessage = "Category name cannot be empty"
            showError = true
            return false
        }

        let isDuplicate = allCategories.contains {
            $0.name.lowercased() == trimmedName.lowercased() && !$0.isHidden
        }
        guard !isDuplicate else {
            errorMessage = "\"\(trimmedName)\" already exists"
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
            try modelContext.save()
            
            let payload = try? APIClient.apiEncoder.encode(category.toCreateRequest())
            changeQueue.enqueue(
                entityType: "category",
                entityID: category.id,
                action: "create",
                endpoint: "/categories",
                httpMethod: "POST",
                payload: payload,
                context: modelContext
            )
            
            if NetworkMonitor.shared.isConnected {
                Task {
                    await changeQueue.replayAll(context: modelContext, isAuthenticated: auth.isAuthenticated)
                }
            }
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

@MainActor
class EditCategoryViewModel: CategoryEditorViewModel {
    var name: String
    var isSaving = false
    var showError = false
    var errorMessage = ""
    
    let category: CustomCategory
    var modelContext: ModelContext?
    private let changeQueue: ChangeQueueManagerProtocol
    private let auth: AuthServiceProtocol

    override var colorConflictCategory: String? {
        allCategories.first(where: {
            $0.id != category.id &&
            $0.color.lowercased() == selectedColor.lowercased() &&
            !$0.isHidden
        })?.name
    }

    init(category: CustomCategory, allCategories: [CustomCategory] = [], changeQueue: ChangeQueueManagerProtocol = changeQueueManager, auth: AuthServiceProtocol = authService) {
        self.category = category
        self.name = category.name
        self.changeQueue = changeQueue
        self.auth = auth
        super.init(icon: category.icon, color: category.color)
        self.allCategories = allCategories
    }
    
    func save() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else {
            errorMessage = "Category name cannot be empty"
            showError = true
            return false
        }

        let isDuplicate = allCategories.contains {
            $0.id != category.id &&
            $0.name.lowercased() == trimmedName.lowercased() &&
            !$0.isHidden
        }
        guard !isDuplicate else {
            errorMessage = "\"\(trimmedName)\" already exists"
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

        // Cascade rename to all linked Transactions and RecurringExpenses
        if oldName != trimmedName {
            let categoryId = category.id

            let transactionDescriptor = FetchDescriptor<Transaction>()
            if let transactions = try? modelContext.fetch(transactionDescriptor) {
                for transaction in transactions {
                    if transaction.categoryId == categoryId || transaction.category == oldName {
                        transaction.category = trimmedName
                        if transaction.categoryId == nil { transaction.categoryId = categoryId }
                        transaction.updatedAt = Date()
                    }
                }
            }

            let recurringDescriptor = FetchDescriptor<RecurringExpense>()
            if let recurrings = try? modelContext.fetch(recurringDescriptor) {
                for recurring in recurrings {
                    if recurring.categoryId == categoryId || recurring.category == oldName {
                        recurring.category = trimmedName
                        if recurring.categoryId == nil { recurring.categoryId = categoryId }
                        recurring.updatedAt = Date()
                    }
                }
            }
        }

        do {
            try modelContext.save()
            
            let payload = try? APIClient.apiEncoder.encode(category.toUpdateRequest())
            changeQueue.enqueue(
                entityType: "category",
                entityID: category.id,
                action: "update",
                endpoint: "/categories",
                httpMethod: "PUT",
                payload: payload,
                context: modelContext
            )
            
            if NetworkMonitor.shared.isConnected {
                Task {
                    await changeQueue.replayAll(context: modelContext, isAuthenticated: auth.isAuthenticated)
                }
            }
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

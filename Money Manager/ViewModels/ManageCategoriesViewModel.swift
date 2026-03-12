import SwiftUI
import SwiftData
import Combine

@MainActor
class ManageCategoriesViewModel: ObservableObject {
    @Published var showAddCategory = false
    @Published var categoryToEdit: CustomCategory?
    @Published var categoryToDelete: CustomCategory?
    @Published var showDeleteConfirmation = false
    
    private var modelContext: ModelContext?
    
    // Legacy computed properties kept for test compatibility
    var customCategories: [CustomCategory] = []
    
    var visibleCategories: [CustomCategory] {
        customCategories.filter { !$0.isHidden }
    }
    
    var hiddenCategories: [CustomCategory] {
        customCategories.filter { $0.isHidden }
    }
    
    func configure(modelContext: ModelContext?) {
        self.modelContext = modelContext
    }
    
    func configure(customCategories: [CustomCategory], modelContext: ModelContext?) {
        self.customCategories = customCategories
        self.modelContext = modelContext
    }
    
    func hideCategory(_ category: CustomCategory) {
        category.isHidden = true
        category.updatedAt = Date()
        try? modelContext?.save()
    }
    
    func hideCategory(at index: Int) {
        let visible = customCategories.filter { !$0.isHidden && !$0.isPredefined }
        guard index < visible.count else { return }
        hideCategory(visible[index])
    }
    
    func restoreCategory(_ category: CustomCategory) {
        category.isHidden = false
        category.updatedAt = Date()
        try? modelContext?.save()
    }
    
    func deleteCategory(_ category: CustomCategory) {
        guard category.isDeletable else { return }
        categoryToDelete = category
        showDeleteConfirmation = true
    }
    
    func confirmDelete() {
        guard let category = categoryToDelete else { return }
        modelContext?.delete(category)
        try? modelContext?.save()
        categoryToDelete = nil
    }
}

@MainActor
class CategoryEditorViewModel: ObservableObject {
    @Published var selectedIcon: String
    @Published var selectedColor: String
    @Published var showColorWarning = false
    @Published var colorWarningMessage = ""
    
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
    @Published var name = ""
    @Published var isSaving = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    var modelContext: ModelContext?
    
    override var colorConflictCategory: String? {
        allCategories.first(where: {
            $0.color.lowercased() == selectedColor.lowercased() && !$0.isHidden
        })?.name
    }
    
    func configure(modelContext: ModelContext?, allCategories: [CustomCategory] = []) {
        self.modelContext = modelContext
        self.allCategories = allCategories
    }
    
    func save() async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        
        guard checkColorConflict() else { return false }
        
        isSaving = true
        resetColorWarning()
        
        let category = CustomCategory(
            name: trimmedName,
            icon: selectedIcon,
            color: selectedColor
        )
        modelContext?.insert(category)
        
        do {
            try modelContext?.save()
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
    @Published var name: String
    @Published var isSaving = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    let category: CustomCategory
    var modelContext: ModelContext?
    
    override var colorConflictCategory: String? {
        allCategories.first(where: {
            $0.id != category.id &&
            $0.color.lowercased() == selectedColor.lowercased() &&
            !$0.isHidden
        })?.name
    }
    
    init(category: CustomCategory, allCategories: [CustomCategory] = []) {
        self.category = category
        self.name = category.name
        super.init(icon: category.icon, color: category.color)
        self.allCategories = allCategories
    }
    
    func configure(modelContext: ModelContext?) {
        self.modelContext = modelContext
    }
    
    func save() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Category name cannot be empty"
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
            try modelContext?.save()
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

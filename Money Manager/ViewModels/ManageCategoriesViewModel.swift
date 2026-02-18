import SwiftUI
import SwiftData
import Combine

@MainActor
class ManageCategoriesViewModel: ObservableObject {
    @Published var showAddCategory = false
    
    var customCategories: [CustomCategory] = []
    var modelContext: ModelContext?
    
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
    
    func hideCategory(at index: Int) {
        guard index < visibleCategories.count else { return }
        let category = visibleCategories[index]
        category.isHidden = true
        category.updatedAt = Date()
        try? modelContext?.save()
    }
    
    func restoreCategory(_ category: CustomCategory) {
        category.isHidden = false
        category.updatedAt = Date()
        try? modelContext?.save()
    }
}

@MainActor
class AddCategoryViewModel: ObservableObject {
    @Published var name = ""
    @Published var selectedIcon = "tag.circle.fill"
    @Published var selectedColor = "#4ECDC4"
    @Published var isSaving = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    var modelContext: ModelContext?
    
    let iconOptions = [
        "tag.circle.fill", "cart.circle.fill", "heart.circle.fill",
        "star.circle.fill", "flame.circle.fill", "drop.circle.fill",
        "leaf.circle.fill", "pawprint.circle.fill", "cup.and.saucer.fill",
        "tshirt.fill", "dumbbell.fill", "paintbrush.circle.fill",
        "music.note", "film.circle.fill", "bicycle.circle.fill",
        "bus.fill", "fuelpump.circle.fill", "wrench.and.screwdriver.fill",
        "camera.circle.fill", "phone.circle.fill", "wifi.circle.fill",
        "banknote.fill", "giftcard.fill", "stroller.fill"
    ]
    
    let colorOptions = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FFEAA7", "#DDA15E", "#BC6C25", "#8E44AD",
        "#3498DB", "#E74C3C", "#F39C12", "#E91E63",
        "#2ECC71", "#1ABC9C", "#9B59B6", "#34495E"
    ]
    
    func configure(modelContext: ModelContext?) {
        self.modelContext = modelContext
    }
    
    func save() -> Bool {
        isSaving = true
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        
        Task {
            do {
                if !MockData.useDummyData {
                    _ = try await APIService.shared.createCategory(
                        name: trimmedName,
                        color: selectedColor,
                        icon: selectedIcon
                    )
                }
                
                let category = CustomCategory(
                    name: trimmedName,
                    icon: selectedIcon,
                    color: selectedColor
                )
                modelContext?.insert(category)
                try modelContext?.save()
                
                isSaving = false
                return true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isSaving = false
                return false
            }
        }
        
        return false
    }
}

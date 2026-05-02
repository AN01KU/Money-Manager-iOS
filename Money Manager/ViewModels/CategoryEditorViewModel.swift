import SwiftUI
import SwiftData

@MainActor
@Observable class CategoryEditorViewModel {
    var selectedIcon: String
    var selectedColor: String
    var showColorWarning = false
    var colorWarningMessage = ""
    
    var allCategories: [CustomCategory] = []
    private var pendingSaveAfterWarning = false
    
    static let iconOptions: [String] = PredefinedCategory.allCases.map(\.icon)
    
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
    
    /// When editing a predefined category, set this to its key so the name-duplicate
    /// check ignores the category's own current name.
    var editingPredefinedKey: String?

    func validateName(_ name: String, excludingId: UUID? = nil) -> (trimmed: String, error: String?) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            return (trimmed, "Category name cannot be empty")
        }

        // Check against all stored categories (custom + predefined overrides)
        let isDuplicate = allCategories.contains {
            (excludingId == nil || $0.id != excludingId) &&
            $0.name.lowercased() == trimmed.lowercased() &&
            !$0.isHidden
        }

        if isDuplicate {
            return (trimmed, "\"\(trimmed)\" already exists")
        }

        return (trimmed, nil)
    }
    
    init(icon: String, color: String) {
        self.selectedIcon = icon
        self.selectedColor = color
    }
    
    convenience init() {
        self.init(icon: AppIcons.Category.other, color: "#17C5CC")
    }
}

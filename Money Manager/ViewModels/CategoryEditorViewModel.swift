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
    
    static var colorPalette: [(color: Color, hex: String)] { AppIcons.CategoryColor.palette }

    static let iconOptions = [
        AppIcons.Category.food,        AppIcons.Category.coffee,
        AppIcons.Category.groceries,   AppIcons.Category.dining,
        AppIcons.Category.transport,   AppIcons.Category.fuel,
        AppIcons.Category.transit,     AppIcons.Category.flights,
        AppIcons.Category.housing,     AppIcons.Category.health,
        AppIcons.Category.pharmacy,    AppIcons.Category.gym,
        AppIcons.Category.yoga,        AppIcons.Category.shopping,
        AppIcons.Category.clothing,    AppIcons.Category.electronics,
        AppIcons.Category.entertainment, AppIcons.Category.music,
        AppIcons.Category.gaming,      AppIcons.Category.books,
        AppIcons.Category.travel,      AppIcons.Category.hotels,
        AppIcons.Category.subscriptions, AppIcons.Category.streaming,
        AppIcons.Category.bills,       AppIcons.Category.phone,
        AppIcons.Category.electricity, AppIcons.Category.insurance,
        AppIcons.Category.education,   AppIcons.Category.courses,
        AppIcons.Category.investments, AppIcons.Category.salary,
        AppIcons.Category.savings,     AppIcons.Category.personalCare,
        AppIcons.Category.haircut,     AppIcons.Category.pets,
        AppIcons.Category.gifts,       AppIcons.Category.work,
        AppIcons.Category.freelance,   AppIcons.Category.atm,
        AppIcons.Category.taxes,       AppIcons.Category.donation,
        AppIcons.Category.baby,        AppIcons.Category.misc,
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
    
    /// Shared name validation used by both Add and Edit flows.
    /// - Parameters:
    ///   - name: The raw name input (will be trimmed).
    ///   - excludingId: Optional category ID to exclude from duplicate check (used by Edit).
    /// - Returns: The trimmed name on success, or `nil` if validation failed (sets `errorMessage`/`showError`).
    /// The predefined category being edited, if any. Set this so its name is
    /// excluded from the "already exists" check when the user keeps the same name.
    var editingPredefinedKey: String?

    func validateName(_ name: String, excludingId: UUID? = nil) -> (trimmed: String, error: String?) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            return (trimmed, "Category name cannot be empty")
        }

        // Check against custom/override rows
        let isDuplicateCustom = allCategories.contains {
            (excludingId == nil || $0.id != excludingId) &&
            $0.name.lowercased() == trimmed.lowercased() &&
            !$0.isHidden
        }

        // Check against predefined enum names (skip the one being edited)
        let isDuplicatePredefined = PredefinedCategory.allCases.contains {
            $0.key != editingPredefinedKey &&
            $0.rawValue.lowercased() == trimmed.lowercased()
        }

        if isDuplicateCustom || isDuplicatePredefined {
            return (trimmed, "\"\(trimmed)\" already exists")
        }

        return (trimmed, nil)
    }
    
    init(icon: String, color: String) {
        self.selectedIcon = icon
        self.selectedColor = color
    }
    
    convenience init() {
        self.init(icon: AppIcons.Category.misc, color: "#17C5CC")
    }
}

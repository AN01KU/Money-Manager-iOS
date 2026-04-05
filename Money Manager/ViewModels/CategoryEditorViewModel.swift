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
    
    /// Shared name validation used by both Add and Edit flows.
    /// - Parameters:
    ///   - name: The raw name input (will be trimmed).
    ///   - excludingId: Optional category ID to exclude from duplicate check (used by Edit).
    /// - Returns: The trimmed name on success, or `nil` if validation failed (sets `errorMessage`/`showError`).
    func validateName(_ name: String, excludingId: UUID? = nil) -> (trimmed: String, error: String?) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        
        guard !trimmed.isEmpty else {
            return (trimmed, "Category name cannot be empty")
        }
        
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
        self.init(icon: "tag.circle.fill", color: "#4ECDC4")
    }
}

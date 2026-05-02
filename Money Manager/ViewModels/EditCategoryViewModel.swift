import SwiftUI
import SwiftData

@MainActor
class EditCategoryViewModel: CategoryEditorViewModel {
    var name: String
    var isSaving = false
    var showError = false
    var errorMessage = ""

    private let category: TransactionCategory
    let persistence: PersistenceService

    var modelContext: ModelContext? {
        get { persistence.modelContext }
        set { persistence.modelContext = newValue }
    }

    override var colorConflictCategory: String? {
        allCategories.first(where: {
            $0.id != category.overrideRow?.id &&
            $0.color.lowercased() == selectedColor.lowercased() &&
            !$0.isHidden
        })?.name
    }

    init(category: TransactionCategory, allCategories: [CustomCategory] = [], persistence: PersistenceService = PersistenceService()) {
        self.category = category
        self.name = category.name
        self.persistence = persistence
        super.init(icon: category.icon, color: category.colorHex)
        self.allCategories = allCategories
        // Exclude the current predefined name from duplicate check
        if category.isPredefined {
            let prefix = "predefined:"
            self.editingPredefinedKey = category.id.hasPrefix(prefix)
                ? String(category.id.dropFirst(prefix.count))
                : nil
        }
    }

    func save() -> Bool {
        let (trimmedName, validationError) = validateName(name, excludingId: category.overrideRow?.id)
        if let validationError {
            errorMessage = validationError
            showError = true
            return false
        }

        guard checkColorConflict() else { return false }
        guard let context = modelContext else { return false }

        isSaving = true
        resetColorWarning()

        if let row = category.overrideRow {
            // Update existing override row — transactions are keyed by server key, not name,
            // so renaming the display name requires no cascade update.
            row.name = trimmedName
            row.icon = selectedIcon
            row.color = selectedColor
            row.updatedAt = Date()

            do {
                try persistence.saveCategory(row, action: "update")
            } catch {
                errorMessage = "Failed to save changes"
                showError = true
                isSaving = false
                return false
            }
        } else if category.isPredefined,
                  let predefined = predefinedCase(for: category) {
            // No override row yet — create one to record the user's changes
            let row = CustomCategory(
                key: predefined.serverKey,
                name: trimmedName,
                icon: selectedIcon,
                color: selectedColor,
                isPredefined: true,
                predefinedKey: predefined.serverKey
            )
            context.insert(row)

            do {
                try persistence.saveCategory(row, action: "create")
            } catch {
                errorMessage = "Failed to save changes"
                showError = true
                isSaving = false
                return false
            }
        }

        isSaving = false
        return true
    }

    // MARK: - Private

    private func predefinedCase(for category: TransactionCategory) -> PredefinedCategory? {
        let prefix = "predefined:"
        guard category.id.hasPrefix(prefix) else { return nil }
        let key = String(category.id.dropFirst(prefix.count))
        return PredefinedCategory.allCases.first { $0.serverKey == key }
    }
}

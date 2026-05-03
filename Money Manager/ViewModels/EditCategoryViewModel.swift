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
            !$0.isServerPredefined &&
            $0.id != category.overrideRow?.id &&
            $0.color.lowercased() == selectedColor.lowercased() &&
            !$0.isHidden
        })?.name
    }

    init(category: TransactionCategory, allCategories: [Category] = [], persistence: PersistenceService = PersistenceService()) {
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
        let logName = name
        let logIcon = selectedIcon
        let logColor = selectedColor
        let logCategoryId = category.id
        let logIsPredefined = category.isPredefined
        let logOverrideId = category.overrideRow?.id.uuidString ?? "nil"
        let logAllCount = allCategories.count
        let logPredKey = editingPredefinedKey ?? "nil"
        AppLogger.data.debug("[EditCategory] save() called — name=\(logName) icon=\(logIcon) color=\(logColor)")
        AppLogger.data.debug("[EditCategory] category.id=\(logCategoryId) isPredefined=\(logIsPredefined) overrideRow=\(logOverrideId)")
        AppLogger.data.debug("[EditCategory] allCategories.count=\(logAllCount) editingPredefinedKey=\(logPredKey)")

        let (trimmedName, validationError) = validateName(name, excludingId: category.overrideRow?.id)
        AppLogger.data.debug("[EditCategory] validateName -> trimmed=\(trimmedName) error=\(validationError ?? "none")")
        if let validationError {
            errorMessage = validationError
            showError = true
            return false
        }

        guard checkColorConflict() else {
            AppLogger.data.debug("[EditCategory] blocked by color conflict")
            return false
        }
        guard let context = modelContext else {
            AppLogger.data.error("[EditCategory] no modelContext — aborting")
            return false
        }

        isSaving = true
        resetColorWarning()
        if let row = category.overrideRow {
            AppLogger.data.debug("[EditCategory] updating existing override row id=\(row.id)")
            row.name = trimmedName
            row.icon = selectedIcon
            row.color = selectedColor
            row.updatedAt = Date()

            do {
                try persistence.saveCategory(row, action: "update")
                AppLogger.data.debug("[EditCategory] update saved ok")
            } catch {
                AppLogger.data.error("[EditCategory] update failed: \(error)")
                errorMessage = "Failed to save changes"
                showError = true
                isSaving = false
                return false
            }
        } else if category.isPredefined {
            let predefined = predefinedCase(for: category)
            let serverKey = category.key
            AppLogger.data.debug("[EditCategory] no override row — predefinedCase=\(predefined?.serverKey ?? "nil") category.key=\(serverKey)")

            // No override row yet — create one. Use category.key directly since
            // server-predefined rows may not be in the PredefinedCategory enum.
            let row = Category(
                key: serverKey,
                name: trimmedName,
                icon: selectedIcon,
                color: selectedColor,
                isPredefined: true,
                predefinedKey: serverKey
            )
            context.insert(row)
            AppLogger.data.debug("[EditCategory] inserted new override row id=\(row.id) key=\(serverKey)")

            do {
                try persistence.saveCategory(row, action: "create")
                AppLogger.data.debug("[EditCategory] create saved ok")
            } catch {
                AppLogger.data.error("[EditCategory] create failed: \(error)")
                errorMessage = "Failed to save changes"
                showError = true
                isSaving = false
                return false
            }
        } else {
            AppLogger.data.error("[EditCategory] save() fell through — no branch matched")
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

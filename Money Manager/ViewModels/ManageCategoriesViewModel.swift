import SwiftUI
import SwiftData

@MainActor
@Observable class ManageCategoriesViewModel {
    var showAddCategory = false
    var categoryToEdit: TransactionCategory?
    var categoryToDelete: TransactionCategory?
    var showDeleteConfirmation = false

    let persistence: PersistenceService

    var modelContext: ModelContext? {
        get { persistence.modelContext }
        set { persistence.modelContext = newValue }
    }

    init(persistence: PersistenceService = PersistenceService()) {
        self.persistence = persistence
    }

    func hideCategory(_ category: TransactionCategory) {
        if category.isPredefined {
            // Predefined hides are local-only — no backend sync
            if let row = category.overrideRow {
                row.isHidden = true
                row.updatedAt = Date()
            } else if let predefined = predefinedCase(for: category),
                      let context = modelContext {
                let row = CustomCategory(
                    name: predefined.rawValue,
                    icon: predefined.icon,
                    color: predefined.defaultColorHex,
                    isPredefined: true,
                    predefinedKey: predefined.key
                )
                row.isHidden = true
                context.insert(row)
            }
            try? persistence.save()
        } else if let row = category.overrideRow {
            // Custom category hide — sync to backend
            row.isHidden = true
            row.updatedAt = Date()
            try? persistence.saveCategory(row, action: "update")
        }
        AppLogger.data.info("Category hidden: \(category.name)")
    }

    func restoreCategory(_ category: TransactionCategory) {
        guard let row = category.overrideRow else { return }
        row.isHidden = false
        row.updatedAt = Date()
        if category.isPredefined {
            try? persistence.save()
        } else {
            try? persistence.saveCategory(row, action: "update")
        }
        AppLogger.data.info("Category restored: \(category.name)")
    }

    func deleteCategory(_ category: TransactionCategory) {
        guard category.isDeletable else { return }
        categoryToDelete = category
        showDeleteConfirmation = true
    }

    func confirmDelete() {
        guard let category = categoryToDelete, let context = modelContext else { return }

        if let row = category.overrideRow {
            let categoryName = row.name
            let categoryId = row.id

            let txDescriptor = FetchDescriptor<Transaction>()
            if let transactions = try? context.fetch(txDescriptor) {
                for tx in transactions where tx.categoryId == categoryId {
                    tx.category = "Other"
                    tx.categoryId = nil
                    tx.updatedAt = Date()
                }
            }

            let recurringDescriptor = FetchDescriptor<RecurringTransaction>()
            if let recurrings = try? context.fetch(recurringDescriptor) {
                for r in recurrings where r.categoryId == categoryId {
                    r.category = "Other"
                    r.categoryId = nil
                    r.updatedAt = Date()
                }
            }

            context.delete(row)
            try? persistence.saveAndSync(
                entityType: "category",
                entityID: categoryId,
                action: "delete",
                endpoint: "/categories",
                httpMethod: "DELETE",
                payload: nil
            )
            AppLogger.data.info("Category deleted: \(categoryName)")
        }
        // A predefined with no override row has nothing to delete locally

        categoryToDelete = nil
        showDeleteConfirmation = false
        deleteConfirmedTrigger += 1
    }

    var deleteConfirmedTrigger: Int = 0

    /// Resets predefined overrides to enum defaults by deleting the override rows.
    func restoreDefaults(modelContext: ModelContext?) {
        guard let context = modelContext else { return }
        persistence.modelContext = context

        let descriptor = FetchDescriptor<CustomCategory>(
            predicate: #Predicate { $0.isPredefined == true }
        )
        guard let rows = try? context.fetch(descriptor) else { return }
        for row in rows { context.delete(row) }
        try? context.save()
        AppLogger.data.info("Default categories restored")
        resetTrigger += 1
    }

    var resetTrigger: Int = 0

    /// Deletes all CustomCategory rows — custom categories and predefined overrides.
    /// After this, the PredefinedCategory enum is the sole source of truth.
    func resetAll(modelContext: ModelContext?) {
        guard let context = modelContext else { return }
        try? context.delete(model: CustomCategory.self)
        try? context.save()
        resetTrigger += 1
    }

    // MARK: - Helpers

    private func predefinedCase(for category: TransactionCategory) -> PredefinedCategory? {
        // id format: "predefined:<key>"
        let prefix = "predefined:"
        guard category.id.hasPrefix(prefix) else { return nil }
        let key = String(category.id.dropFirst(prefix.count))
        return PredefinedCategory.allCases.first { $0.key == key }
    }
}

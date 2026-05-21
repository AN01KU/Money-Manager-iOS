import SwiftUI
import SwiftData

@MainActor
@Observable class ManageCategoriesViewModel {
    var showAddCategory = false
    var categoryToEdit: TransactionCategory?
    var categoryToDelete: TransactionCategory?
    var showDeleteConfirmation = false

    @ObservationIgnored var persistence: PersistenceService

    var modelContext: ModelContext { persistence.modelContext }

    init(persistence: PersistenceService = .testing) {
        self.persistence = persistence
    }

    func hideCategory(_ category: TransactionCategory) {
        if let row = category.overrideRow {
            row.isHidden = true
            row.updatedAt = Date()
            try? persistence.save(row, action: .update)
        } else if category.isPredefined {
            let context = modelContext
            let row = Category.makeOverride(for: category)
            row.isHidden = true
            context.insert(row)
            try? persistence.save(row, action: .create)
        }
        AppLogger.data.info("Category hidden: \(category.name)")
    }

    func restoreCategory(_ category: TransactionCategory) {
        guard let row = category.overrideRow else { return }
        row.isHidden = false
        row.updatedAt = Date()
        try? persistence.save(row, action: .update)
        AppLogger.data.info("Category restored: \(category.name)")
    }

    func deleteCategory(_ category: TransactionCategory) {
        guard category.isDeletable else { return }
        categoryToDelete = category
        showDeleteConfirmation = true
    }

    func confirmDelete() {
        guard let category = categoryToDelete else { return }
        let context = modelContext

        if let row = category.overrideRow {
            let categoryName = row.name
            let categoryId = row.id

            let fallback = PredefinedCategory.other.serverKey
            let txDescriptor = FetchDescriptor<Transaction>()
            if let transactions = try? context.fetch(txDescriptor) {
                for tx in transactions where tx.categoryId == categoryId {
                    tx.category = fallback
                    tx.categoryId = nil
                    tx.updatedAt = Date()
                }
            }

            let recurringDescriptor = FetchDescriptor<RecurringTransaction>()
            if let recurrings = try? context.fetch(recurringDescriptor) {
                for r in recurrings where r.categoryId == categoryId {
                    r.category = fallback
                    r.categoryId = nil
                    r.updatedAt = Date()
                }
            }

            context.delete(row)
            try? persistence.deleteCategory(id: categoryId)
            AppLogger.data.info("Category deleted: \(categoryName)")
        }
        // A predefined with no override row has nothing to delete locally

        categoryToDelete = nil
        showDeleteConfirmation = false
        deleteConfirmedTrigger += 1
    }

    var deleteConfirmedTrigger: Int = 0

    /// Resets predefined overrides to enum defaults by deleting the override rows.
    func restoreDefaults() {
        let context = modelContext
        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.isPredefined == true })
        deleteAndSync(rows: (try? context.fetch(descriptor)) ?? [], context: context)
        AppLogger.data.info("Default categories restored")
        resetTrigger += 1
    }

    var resetTrigger: Int = 0

    /// Deletes all Category rows — custom categories and predefined overrides.
    /// After this, the PredefinedCategory enum is the sole source of truth.
    func resetAll() {
        let context = modelContext
        deleteAndSync(rows: (try? context.fetch(FetchDescriptor<Category>())) ?? [], context: context)
        resetTrigger += 1
    }

    private func deleteAndSync(rows: [Category], context: ModelContext) {
        for row in rows {
            let rowID = row.id
            context.delete(row)
            try? persistence.deleteCategory(id: rowID)
        }
    }

}

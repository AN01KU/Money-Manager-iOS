import SwiftUI
import SwiftData

@MainActor
@Observable class ManageCategoriesViewModel {
    var showAddCategory = false
    var categoryToEdit: Category?
    var categoryToDelete: Category?
    var showDeleteConfirmation = false

    @ObservationIgnored var persistence: PersistenceService

    var modelContext: ModelContext { persistence.modelContext }

    init(persistence: PersistenceService = .testing) {
        self.persistence = persistence
    }

    func hideCategory(_ category: Category) {
        category.isHidden = true
        category.updatedAt = Date()
        try? persistence.save(category, action: .update)
        AppLogger.data.info("Category hidden: \(category.name)")
    }

    func restoreCategory(_ category: Category) {
        category.isHidden = false
        category.updatedAt = Date()
        try? persistence.save(category, action: .update)
        AppLogger.data.info("Category restored: \(category.name)")
    }

    func deleteCategory(_ category: Category) {
        guard category.isDeletable else { return }
        categoryToDelete = category
        showDeleteConfirmation = true
    }

    func confirmDelete() {
        guard let category = categoryToDelete else { return }
        let context = modelContext
        let categoryId = category.id
        let categoryName = category.name

        // Reassign transactions referencing this category to Other.
        if let otherRow = (try? context.fetch(FetchDescriptor<Category>(
            predicate: #Predicate { $0.key == "other" }
        )))?.first {
            let txDescriptor = FetchDescriptor<Transaction>()
            if let transactions = try? context.fetch(txDescriptor) {
                for tx in transactions where tx.categoryId == categoryId {
                    tx.categoryId = otherRow.id
                    tx.updatedAt = Date()
                }
            }

            let recurringDescriptor = FetchDescriptor<RecurringTransaction>()
            if let recurrings = try? context.fetch(recurringDescriptor) {
                for r in recurrings where r.categoryId == categoryId {
                    r.categoryId = otherRow.id
                    r.updatedAt = Date()
                }
            }
        }

        context.delete(category)
        try? persistence.deleteCategory(id: categoryId)
        AppLogger.data.info("Category deleted: \(categoryName)")

        categoryToDelete = nil
        showDeleteConfirmation = false
        deleteConfirmedTrigger += 1
    }

    var deleteConfirmedTrigger: Int = 0

    func restoreDefaults() {
        let context = modelContext
        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.isPredefined == true })
        deleteAndSync(rows: (try? context.fetch(descriptor)) ?? [], context: context)
        AppLogger.data.info("Default categories restored")
        resetTrigger += 1
    }

    var resetTrigger: Int = 0

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

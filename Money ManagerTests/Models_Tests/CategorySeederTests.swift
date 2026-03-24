import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct CategorySeederTests {
    
    @Test
    func testSeedIfNeededDoesNothingWhenCategoriesExist() {
        let context = createTestContext()
        
        let existing = CustomCategory(
            name: "Food",
            icon: "fork.knife",
            color: "#FF0000",
            isPredefined: true,
            predefinedKey: "food"
        )
        context.insert(existing)
        try? context.save()
        
        CategorySeeder.seedIfNeeded(context: context)
        
        let descriptor = FetchDescriptor<CustomCategory>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        
        #expect(count == 1)
    }
    
    @Test
    func testSeedIfNeededCreatesCategoriesWhenNoneExist() {
        let context = createTestContext()
        
        CategorySeeder.seedIfNeeded(context: context)
        
        let descriptor = FetchDescriptor<CustomCategory>(
            predicate: #Predicate { $0.isPredefined == true }
        )
        let count = (try? context.fetchCount(descriptor)) ?? 0
        
        #expect(count == PredefinedCategory.allCases.count)
    }
    
    @Test
    func testSeedIfNeededCreatesAllPredefinedCategories() {
        let context = createTestContext()
        
        CategorySeeder.seedIfNeeded(context: context)
        
        let descriptor = FetchDescriptor<CustomCategory>(
            predicate: #Predicate { $0.isPredefined == true }
        )
        let categories = (try? context.fetch(descriptor)) ?? []
        
        #expect(categories.count == PredefinedCategory.allCases.count)
        
        let createdKeys = Set(categories.compactMap { $0.predefinedKey })
        let expectedKeys = Set(PredefinedCategory.allCases.map { $0.key })
        
        #expect(createdKeys == expectedKeys)
    }
    
    private func createTestContext() -> ModelContext {
        let schema = Schema([CustomCategory.self, Expense.self, RecurringExpense.self, MonthlyBudget.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }
}

import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct AddExpenseViewModelTests {
    
    private func makeContext() -> ModelContext {
        let schema = Schema([Expense.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        return ModelContext(container)
    }
    
    // MARK: - Validation
    
    @Test
    func testIsValidRequiresPositiveAmountAndCategory() {
        let vm = AddExpenseViewModel(mode: .personal())
        
        #expect(vm.isValid == false) // empty amount + category
        
        vm.amount = "500"
        #expect(vm.isValid == false) // empty category
        
        vm.selectedCategory = "Food"
        #expect(vm.isValid == true)
        
        vm.amount = "0"
        #expect(vm.isValid == false) // zero amount
        
        vm.amount = "-10"
        #expect(vm.isValid == false) // negative
        
        vm.amount = "abc"
        #expect(vm.isValid == false) // non-numeric
    }
    
    // MARK: - Navigation Title
    
    @Test
    func testNavigationTitle() {
        let addVM = AddExpenseViewModel(mode: .personal())
        #expect(addVM.navigationTitle == "Add Expense")
        
        let expense = Expense(amount: 100, category: "Food", date: Date())
        let editVM = AddExpenseViewModel(mode: .personal(editing: expense))
        #expect(editVM.navigationTitle == "Edit Expense")
    }
    
    // MARK: - Setup from existing expense
    
    @Test
    func testSetupPopulatesFieldsFromExpense() {
        let expense = Expense(
            amount: 250.50,
            category: "Transport",
            date: Date(),
            time: Date(),
            expenseDescription: "Taxi",
            notes: "Airport trip"
        )
        let vm = AddExpenseViewModel(mode: .personal(editing: expense))
        vm.setup()
        
        #expect(vm.amount == "250.50")
        #expect(vm.selectedCategory == "Transport")
        #expect(vm.description == "Taxi")
        #expect(vm.notes == "Airport trip")
        #expect(vm.hasTime == true)
    }
    
    @Test
    func testSetupWithNoTimeExpense() {
        let expense = Expense(amount: 100, category: "Food", date: Date())
        let vm = AddExpenseViewModel(mode: .personal(editing: expense))
        vm.setup()
        
        #expect(vm.hasTime == false)
        #expect(vm.description == "")
        #expect(vm.notes == "")
    }
    
    @Test
    func testSetupDoesNothingForNewExpenseMode() {
        let vm = AddExpenseViewModel(mode: .personal())
        vm.setup()
        
        #expect(vm.amount.isEmpty)
        #expect(vm.selectedCategory.isEmpty)
    }
    
    // MARK: - Format helpers
    
    @Test
    func testFormatDateAndTime() {
        let vm = AddExpenseViewModel(mode: .personal())
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        
        let dateStr = vm.formatDate(date)
        #expect(dateStr.contains("Mar") || dateStr.contains("15"))
        
        let timeStr = vm.formatTime(date)
        #expect(!timeStr.isEmpty)
    }
    
    // MARK: - Save: new expense
    
    @Test
    func testSaveCreatesNewExpense() throws {
        let context = makeContext()
        let vm = AddExpenseViewModel(mode: .personal())
        vm.modelContext = context
        
        vm.amount = "150.75"
        vm.selectedCategory = "Food & Dining"
        vm.description = "Lunch"
        vm.notes = "With team"
        vm.hasTime = true
        
        var completed = false
        vm.save { completed = true }
        
        #expect(completed == true)
        #expect(vm.isSaving == false)
        #expect(vm.showError == false)
        
        let expenses = try context.fetch(FetchDescriptor<Expense>())
        #expect(expenses.count == 1)
        #expect(expenses.first?.amount == 150.75)
        #expect(expenses.first?.category == "Food & Dining")
        #expect(expenses.first?.expenseDescription == "Lunch")
        #expect(expenses.first?.notes == "With team")
        #expect(expenses.first?.time != nil)
    }
    
    @Test
    func testSaveWithoutTimeSetTimeToNil() throws {
        let context = makeContext()
        let vm = AddExpenseViewModel(mode: .personal())
        vm.modelContext = context
        
        vm.amount = "100"
        vm.selectedCategory = "Transport"
        vm.hasTime = false
        
        vm.save {}
        
        let expenses = try context.fetch(FetchDescriptor<Expense>())
        #expect(expenses.first?.time == nil)
    }
    
    @Test
    func testSaveWithEmptyDescriptionAndNotesSetsNil() throws {
        let context = makeContext()
        let vm = AddExpenseViewModel(mode: .personal())
        vm.modelContext = context
        
        vm.amount = "50"
        vm.selectedCategory = "Other"
        vm.description = ""
        vm.notes = ""
        
        vm.save {}
        
        let expenses = try context.fetch(FetchDescriptor<Expense>())
        #expect(expenses.first?.expenseDescription == nil)
        #expect(expenses.first?.notes == nil)
    }
    
    // MARK: - Save: edit existing expense
    
    @Test
    func testSaveUpdatesExistingExpense() throws {
        let context = makeContext()
        let existing = Expense(
            amount: 100,
            category: "Food",
            date: Date(),
            time: Date(),
            expenseDescription: "Old",
            notes: "Old note"
        )
        context.insert(existing)
        try context.save()
        
        let vm = AddExpenseViewModel(mode: .personal(editing: existing))
        vm.modelContext = context
        
        vm.amount = "200"
        vm.selectedCategory = "Transport"
        vm.description = "Updated"
        vm.notes = ""
        vm.hasTime = false
        
        var completed = false
        vm.save { completed = true }
        
        #expect(completed == true)
        #expect(existing.amount == 200)
        #expect(existing.category == "Transport")
        #expect(existing.expenseDescription == "Updated")
        #expect(existing.notes == nil)
        #expect(existing.time == nil)
    }
    
    // MARK: - Save: validation failures
    
    @Test
    func testSaveFailsWithZeroAmount() {
        let context = makeContext()
        let vm = AddExpenseViewModel(mode: .personal())
        vm.modelContext = context
        vm.amount = "0"
        vm.selectedCategory = "Food"
        
        var completed = false
        vm.save { completed = true }
        
        #expect(completed == false)
        #expect(vm.showError == true)
        print(vm.errorMessage)
        #expect(vm.errorMessage.contains("amount"))
    }
    
    @Test
    func testSaveFailsWithNonNumericAmount() {
        let context = makeContext()
        let vm = AddExpenseViewModel(mode: .personal())
        vm.modelContext = context
        vm.amount = "abc"
        vm.selectedCategory = "Food"
        
        var completed = false
        vm.save { completed = true }
        
        #expect(completed == false)
        #expect(vm.showError == true)
    }
    
    @Test
    func testSaveWithNoModelContextDoesNothing() {
        let vm = AddExpenseViewModel(mode: .personal())
        // No configure() call — modelContext is nil
        vm.amount = "100"
        vm.selectedCategory = "Food"
        
        var completed = false
        vm.save { completed = true }
        
        #expect(completed == false)
    }
    
    // MARK: - Save: date handling
    
    @Test
    func testSaveSetsCorrectDateWithTime() throws {
        let context = makeContext()
        let vm = AddExpenseViewModel(mode: .personal())
        vm.modelContext = context
        
        let specificDate = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let specificTime = Calendar.current.date(from: DateComponents(hour: 14, minute: 30))!
        
        vm.amount = "100"
        vm.selectedCategory = "Food"
        vm.selectedDate = specificDate
        vm.selectedTime = specificTime
        vm.hasTime = true
        
        vm.save {}
        
        let expenses = try context.fetch(FetchDescriptor<Expense>())
        let saved = expenses.first!
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: saved.date)
        #expect(components.year == 2026)
        #expect(components.month == 6)
        #expect(components.day == 15)
        #expect(components.hour == 14)
        #expect(components.minute == 30)
    }
    
    @Test
    func testSaveSetsStartOfDayWhenNoTime() throws {
        let context = makeContext()
        let vm = AddExpenseViewModel(mode: .personal())
        vm.modelContext = context
        
        let specificDate = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 18, minute: 45))!
        
        vm.amount = "100"
        vm.selectedCategory = "Food"
        vm.selectedDate = specificDate
        vm.hasTime = false
        
        vm.save {}
        
        let expenses = try context.fetch(FetchDescriptor<Expense>())
        let saved = expenses.first!
        let components = Calendar.current.dateComponents([.hour, .minute], from: saved.date)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
    }
}

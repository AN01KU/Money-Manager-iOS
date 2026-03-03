import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct RecurringExpensesViewModelTests {
    
    @Test
    func testActiveExpensesFiltersOutInactive() {
        let viewModel = RecurringExpensesViewModel()
        
        let active1 = Expense(amount: 649, category: "Entertainment", date: Date(), expenseDescription: "Netflix", isRecurring: true, frequency: "monthly")
        let active2 = Expense(amount: 500, category: "Health", date: Date(), expenseDescription: "Gym", isRecurring: true, frequency: "monthly")
        let inactive = Expense(amount: 100, category: "Other", date: Date(), expenseDescription: "Old", isRecurring: true, frequency: "monthly")
        inactive.isActive = false
        
        viewModel.configure(expenses: [active1, active2, inactive], modelContext: nil)
        
        #expect(viewModel.activeExpenses.count == 2)
    }
    
    @Test
    func testActiveExpensesReturnsEmptyWhenAllInactive() {
        let viewModel = RecurringExpensesViewModel()
        
        let inactive = Expense(amount: 100, category: "Other", date: Date(), expenseDescription: "Old", isRecurring: true, frequency: "monthly")
        inactive.isActive = false
        
        viewModel.configure(expenses: [inactive], modelContext: nil)
        
        #expect(viewModel.activeExpenses.isEmpty)
    }
    
    @Test
    func testActiveExpensesOnlyIncludesRecurring() {
        let viewModel = RecurringExpensesViewModel()
        
        let recurring = Expense(amount: 649, category: "Entertainment", date: Date(), expenseDescription: "Netflix", isRecurring: true, frequency: "monthly")
        let nonRecurring = Expense(amount: 500, category: "Food", date: Date(), expenseDescription: "Lunch")
        
        viewModel.configure(expenses: [recurring, nonRecurring], modelContext: nil)
        
        #expect(viewModel.activeExpenses.count == 1)
        #expect(viewModel.activeExpenses.first?.expenseDescription == "Netflix")
    }
}

@MainActor
struct AddRecurringExpenseViewModelTests {
    
    @Test
    func testIsValidWithAllRequiredFields() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"
        
        #expect(viewModel.isValid == true)
    }
    
    @Test
    func testIsValidFailsWithEmptyName() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = ""
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"
        
        #expect(viewModel.isValid == false)
    }
    
    @Test
    func testIsValidFailsWithWhitespaceName() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "   "
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"
        
        #expect(viewModel.isValid == false)
    }
    
    @Test
    func testIsValidFailsWithZeroAmount() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "0"
        viewModel.selectedCategory = "Entertainment"
        
        #expect(viewModel.isValid == false)
    }
    
    @Test
    func testIsValidFailsWithNegativeAmount() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "-100"
        viewModel.selectedCategory = "Entertainment"
        
        #expect(viewModel.isValid == false)
    }
    
    @Test
    func testIsValidFailsWithInvalidAmount() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "abc"
        viewModel.selectedCategory = "Entertainment"
        
        #expect(viewModel.isValid == false)
    }
    
    @Test
    func testIsValidFailsWithEmptyCategory() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "649"
        viewModel.selectedCategory = ""
        
        #expect(viewModel.isValid == false)
    }
    
    @Test
    func testSaveFailsWithInvalidAmount() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "abc"
        viewModel.selectedCategory = "Entertainment"
        
        let result = viewModel.save()
        
        #expect(result == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage.contains("Amount"))
    }
    
    @Test
    func testSaveFailsWithEmptyName() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = ""
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"
        
        let result = viewModel.save()
        
        #expect(result == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage.contains("name"))
    }
    
    @Test
    func testSaveFailsWithEmptyCategory() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "649"
        viewModel.selectedCategory = ""
        
        let result = viewModel.save()
        
        #expect(result == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage.contains("category"))
    }
    
    @Test
    func testSaveTrimsWhitespaceFromName() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "  Netflix  "
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"
        viewModel.frequency = "monthly"
        viewModel.dayOfMonth = 1
        
        let result = viewModel.save()
        
        #expect(result == true)
    }
    
    @Test
    func testFrequenciesContainsStandardOptions() {
        let viewModel = AddRecurringExpenseViewModel()
        
        #expect(viewModel.frequencies.contains("daily"))
        #expect(viewModel.frequencies.contains("weekly"))
        #expect(viewModel.frequencies.contains("monthly"))
        #expect(viewModel.frequencies.contains("yearly"))
    }
}

import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct RecurringExpensesViewModelTests {
    
    @Test
    func testActiveExpensesFiltersOutInactive() {
        let viewModel = RecurringExpensesViewModel()
        
        let active1 = RecurringExpense(name: "Netflix", amount: 649, category: "Entertainment", frequency: "monthly", startDate: Date())
        let active2 = RecurringExpense(name: "Gym", amount: 500, category: "Health", frequency: "monthly", startDate: Date())
        let inactive = RecurringExpense(name: "Old", amount: 100, category: "Other", frequency: "monthly", startDate: Date())
        inactive.isActive = false
        
        viewModel.configure(recurringExpenses: [active1, active2, inactive], modelContext: nil)
        
        #expect(viewModel.activeExpenses.count == 2)
    }
    
    @Test
    func testActiveExpensesReturnsEmptyWhenAllInactive() {
        let viewModel = RecurringExpensesViewModel()
        
        let inactive = RecurringExpense(name: "Old", amount: 100, category: "Other", frequency: "monthly", startDate: Date())
        inactive.isActive = false
        
        viewModel.configure(recurringExpenses: [inactive], modelContext: nil)
        
        #expect(viewModel.activeExpenses.isEmpty)
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

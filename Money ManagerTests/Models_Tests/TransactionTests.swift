import Foundation
import Testing
@testable import Money_Manager

struct TransactionModelTests {
    
    @Test
    func testTransactionInitializationWithDefaultValues() {
        let transaction = Transaction(
            category: .food,
            description: "Lunch",
            amount: 500,
            date: Date()
        )
        
        #expect(transaction.category == .food)
        #expect(transaction.description == "Lunch")
        #expect(transaction.amount == 500)
        #expect(transaction.isRecurring == false)
    }
    
    @Test
    func testTransactionInitializationWithAllParameters() {
        let transactionDate = Date()
        let transaction = Transaction(
            id: UUID(),
            category: .transport,
            description: "Cab ride",
            amount: 250,
            date: transactionDate,
            isRecurring: true
        )
        
        #expect(transaction.category == .transport)
        #expect(transaction.amount == 250)
        #expect(transaction.isRecurring == true)
    }
    
    @Test
    func testTransactionIdIsGeneratedWhenNotProvided() {
        let transaction = Transaction(
            category: .shopping,
            description: "Clothes",
            amount: 1000,
            date: Date()
        )
        
        #expect(transaction.id != nil)
    }
    
    @Test
    func testTransactionWithDifferentCategories() {
        let categories: [Money_Manager.Category] = [.food, .transport, .utilities, .shopping, .housing, .healthMedical, .entertainment, .travel]
        
        for category in categories {
            let transaction = Transaction(category: category, description: "Test", amount: 100, date: Date())
            #expect(transaction.category == category)
        }
    }
    
    @Test
    func testTransactionWithZeroAmount() {
        let transaction = Transaction(
            category: .other,
            description: "Free item",
            amount: 0,
            date: Date()
        )
        
        #expect(transaction.amount == 0)
    }
    
    @Test
    func testTransactionWithNegativeAmount() {
        let transaction = Transaction(
            category: .other,
            description: "Refund",
            amount: -100,
            date: Date()
        )
        
        #expect(transaction.amount == -100)
    }
}

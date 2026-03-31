import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct RecurringTransactionTests {

    @Test
    func isActiveCanBeToggled() {
        let item = RecurringTransaction(name: "Test", amount: 100, category: "Other", frequency: .daily)
        #expect(item.isActive == true)
        item.isActive = false
        #expect(item.isActive == false)
    }
}

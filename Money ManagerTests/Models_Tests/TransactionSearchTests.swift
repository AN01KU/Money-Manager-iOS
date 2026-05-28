import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct TransactionSearchTests {

    private func makeTx(
        categoryId: UUID = UUID(),
        description: String? = nil,
        notes: String? = nil
    ) -> Transaction {
        Transaction(
            type: .expense,
            amount: 10,
            categoryId: categoryId,
            date: Date(),
            transactionDescription: description,
            notes: notes
        )
    }

    // MARK: - Empty search

    @Test func emptySearch_returnsTrue() {
        let tx = makeTx(description: "Lunch", notes: "With Alice")
        #expect(tx.matches(searchText: "") == true)
    }

    // MARK: - Category matching (via categoryName param)

    @Test func matchesCategory_exactMatch() {
        let tx = makeTx()
        #expect(tx.matches(searchText: "Transport", categoryName: "Transport") == true)
    }

    @Test func matchesCategory_caseInsensitive() {
        let tx = makeTx()
        #expect(tx.matches(searchText: "food", categoryName: "Food & Dining") == true)
    }

    @Test func matchesCategory_partialMatch() {
        let tx = makeTx()
        #expect(tx.matches(searchText: "entertain", categoryName: "Entertainment") == true)
    }

    // MARK: - Description matching

    @Test func matchesDescription_caseInsensitive() {
        let tx = makeTx(description: "Coffee at Starbucks")
        #expect(tx.matches(searchText: "coffee") == true)
    }

    @Test func matchesDescription_partialMatch() {
        let tx = makeTx(description: "Grocery run")
        #expect(tx.matches(searchText: "Grocery") == true)
    }

    @Test func nilDescription_doesNotMatch() {
        let tx = makeTx(description: nil)
        #expect(tx.matches(searchText: "lunch") == false)
    }

    // MARK: - Notes matching

    @Test func matchesNotes_caseInsensitive() {
        let tx = makeTx(notes: "Reimbursable expense")
        #expect(tx.matches(searchText: "reimbursable") == true)
    }

    @Test func nilNotes_doesNotMatch() {
        let tx = makeTx(notes: nil)
        #expect(tx.matches(searchText: "receipt") == false)
    }

    // MARK: - No match

    @Test func noMatch_returnsFalse() {
        let tx = makeTx(description: "Rent", notes: "Monthly")
        #expect(tx.matches(searchText: "coffee") == false)
    }
}

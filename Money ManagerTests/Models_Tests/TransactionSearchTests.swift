//
//  TransactionSearchTests.swift
//  Money ManagerTests
//

import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct TransactionSearchTests {

    private func makeTx(
        category: String = "Food & Dining",
        description: String? = nil,
        notes: String? = nil
    ) -> Transaction {
        Transaction(
            type: .expense,
            amount: 10,
            category: category,
            date: Date(),
            transactionDescription: description,
            notes: notes
        )
    }

    // MARK: - Empty search

    @Test func emptySearch_returnsTrue() {
        let tx = makeTx(category: "Food", description: "Lunch", notes: "With Alice")
        #expect(tx.matches(searchText: "") == true)
    }

    // MARK: - Category matching

    @Test func matchesCategory_exactMatch() {
        let tx = makeTx(category: "Transport")
        #expect(tx.matches(searchText: "Transport") == true)
    }

    @Test func matchesCategory_caseInsensitive() {
        let tx = makeTx(category: "Food & Dining")
        #expect(tx.matches(searchText: "food") == true)
    }

    @Test func matchesCategory_partialMatch() {
        let tx = makeTx(category: "Entertainment")
        #expect(tx.matches(searchText: "entertain") == true)
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
        let tx = makeTx(category: "Food", description: nil)
        #expect(tx.matches(searchText: "lunch") == false)
    }

    // MARK: - Notes matching

    @Test func matchesNotes_caseInsensitive() {
        let tx = makeTx(notes: "Reimbursable expense")
        #expect(tx.matches(searchText: "reimbursable") == true)
    }

    @Test func nilNotes_doesNotMatch() {
        let tx = makeTx(category: "Shopping", notes: nil)
        #expect(tx.matches(searchText: "receipt") == false)
    }

    // MARK: - Unicode / normalization

    @Test func matchesUnicode_accentInsensitive() {
        let tx = makeTx(category: "Café")
        // localizedStandardContains handles accent folding
        #expect(tx.matches(searchText: "cafe") == true)
    }

    // MARK: - No match

    @Test func noMatch_returnsFalse() {
        let tx = makeTx(category: "Housing", description: "Rent", notes: "Monthly")
        #expect(tx.matches(searchText: "coffee") == false)
    }
}

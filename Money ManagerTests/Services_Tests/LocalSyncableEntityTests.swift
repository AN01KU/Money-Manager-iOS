import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct LocalSyncableEntityTests {

    // MARK: - Transaction

    @Test func testTransaction_entityType_isTransaction() {
        #expect(Transaction.entityType == .transaction)
    }

    @Test func testTransaction_endpoint_isTransactions() {
        #expect(Transaction.endpoint == "/transactions")
    }

    @Test func testTransaction_createRequestPayload_decodesCorrectFields() throws {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let tx = Transaction(id: id, type: .expense, amount: 150.0, categoryId: UUID(), date: date)

        let data = try tx.createRequestPayload()
        let decoded = try JSONDecoder.apiDecoder.decode(APICreateTransactionRequest.self, from: data)

        #expect(decoded.id == id)
        #expect(decoded.type == .expense)
        #expect(decoded.amount == 150.0)
    }

    @Test func testTransaction_updateRequestPayload_decodesCorrectFields() throws {
        let tx = Transaction(type: .income, amount: 200.0, categoryId: UUID(), date: Date())

        let data = try tx.updateRequestPayload()
        let decoded = try JSONDecoder.apiDecoder.decode(APIUpdateTransactionRequest.self, from: data)

        #expect(decoded.type == .income)
        #expect(decoded.amount == 200.0)
    }

    // MARK: - RecurringTransaction

    @Test func testRecurringTransaction_entityType_isRecurring() {
        #expect(RecurringTransaction.entityType == .recurring)
    }

    @Test func testRecurringTransaction_endpoint_isRecurringTransactions() {
        #expect(RecurringTransaction.endpoint == "/recurring-transactions")
    }

    @Test func testRecurringTransaction_createRequestPayload_decodesCorrectFields() throws {
        let id = UUID()
        let r = RecurringTransaction(id: id, name: "Netflix", amount: 649, categoryId: UUID(), frequency: .monthly)

        let data = try r.createRequestPayload()
        let decoded = try JSONDecoder.apiDecoder.decode(APICreateRecurringTransactionRequest.self, from: data)

        #expect(decoded.id == id)
        #expect(decoded.name == "Netflix")
        #expect(decoded.amount == 649)
        #expect(decoded.frequency == "monthly")
    }

    @Test func testRecurringTransaction_updateRequestPayload_decodesCorrectFields() throws {
        let r = RecurringTransaction(name: "Spotify", amount: 199, categoryId: UUID(), frequency: .weekly)

        let data = try r.updateRequestPayload()
        let decoded = try JSONDecoder.apiDecoder.decode(APIUpdateRecurringTransactionRequest.self, from: data)

        #expect(decoded.name == "Spotify")
        #expect(decoded.amount == 199)
        #expect(decoded.frequency == "weekly")
    }

    // MARK: - Category

    @Test func testCategory_entityType_isCategory() {
        #expect(Category.entityType == .category)
    }

    @Test func testCategory_endpoint_isCategories() {
        #expect(Category.endpoint == "/categories")
    }

    @Test func testCategory_createRequestPayload_decodesCorrectFields() throws {
        let cat = Category(name: "Fitness", icon: "gym", color: "#FF0000")

        let data = try cat.createRequestPayload()
        let decoded = try JSONDecoder.apiDecoder.decode(APICreateCategoryRequest.self, from: data)

        #expect(decoded.name == "Fitness")
        #expect(decoded.icon == "gym")
        #expect(decoded.color == "#FF0000")
    }

    @Test func testCategory_updateRequestPayload_decodesCorrectFields() throws {
        let cat = Category(name: "Health", icon: "heart", color: "#00FF00")

        let data = try cat.updateRequestPayload()
        let decoded = try JSONDecoder.apiDecoder.decode(APIUpdateCategoryRequest.self, from: data)

        #expect(decoded.name == "Health")
        #expect(decoded.icon == "heart")
        #expect(decoded.color == "#00FF00")
    }
}

// MARK: - Helpers

private extension JSONDecoder {
    static var apiDecoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let ms = try container.decode(Int64.self)
            return Date(timeIntervalSince1970: Double(ms) / 1000.0)
        }
        return d
    }
}

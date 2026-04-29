import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct AppRouteTests {

    // MARK: - Parsing valid URLs

    @Test func testTransactionRouteParses() {
        let id = UUID()
        let url = URL(string: "moneymanager://transaction/\(id.uuidString)")!
        let route = AppRoute(url: url)
        if case .transaction(let parsed) = route {
            #expect(parsed == id)
        } else {
            Issue.record("Expected .transaction route, got \(String(describing: route))")
        }
    }

    @Test func testGroupRouteParses() {
        let id = UUID()
        let url = URL(string: "moneymanager://group/\(id.uuidString)")!
        let route = AppRoute(url: url)
        if case .group(let parsed) = route {
            #expect(parsed == id)
        } else {
            Issue.record("Expected .group route, got \(String(describing: route))")
        }
    }

    // MARK: - Invalid / unsupported URLs

    @Test func testWrongSchemeReturnsNil() {
        let url = URL(string: "https://transaction/\(UUID().uuidString)")!
        #expect(AppRoute(url: url) == nil)
    }

    @Test func testUnknownHostReturnsNil() {
        let url = URL(string: "moneymanager://budget/\(UUID().uuidString)")!
        #expect(AppRoute(url: url) == nil)
    }

    @Test func testMissingIdReturnsNil() {
        let url = URL(string: "moneymanager://transaction/not-a-uuid")!
        #expect(AppRoute(url: url) == nil)
    }

    @Test func testEmptyPathReturnsNil() {
        let url = URL(string: "moneymanager://transaction")!
        #expect(AppRoute(url: url) == nil)
    }

    // MARK: - Hashable / Equatable

    @Test func testTransactionRoutesWithSameIDAreEqual() {
        let id = UUID()
        #expect(AppRoute.transaction(id) == AppRoute.transaction(id))
    }

    @Test func testTransactionRoutesWithDifferentIDsAreNotEqual() {
        #expect(AppRoute.transaction(UUID()) != AppRoute.transaction(UUID()))
    }

    @Test func testGroupAndTransactionRoutesWithSameIDAreNotEqual() {
        let id = UUID()
        #expect(AppRoute.transaction(id) != AppRoute.group(id))
    }
}

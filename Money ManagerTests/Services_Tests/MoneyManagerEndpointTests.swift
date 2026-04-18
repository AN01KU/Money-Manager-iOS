import Foundation
import Testing
@testable import Money_Manager

struct MoneyManagerEndpointTests {

    // MARK: - Auth paths

    @Test func testMePath() {
        #expect(MoneyManagerEndpoint.me.path == "/me")
    }

    @Test func testLoginPath() {
        #expect(MoneyManagerEndpoint.login.path == "/auth/login")
    }

    @Test func testSignupPath() {
        #expect(MoneyManagerEndpoint.signup.path == "/auth/signup")
    }

    @Test func testLogoutPath() {
        #expect(MoneyManagerEndpoint.logout.path == "/auth/logout")
    }

    @Test func testHealthPath() {
        #expect(MoneyManagerEndpoint.health.path == "/health")
    }

    // MARK: - Sync paths

    @Test func testSyncPreflightPath() {
        #expect(MoneyManagerEndpoint.syncPreflight.path == "/sync/preflight")
    }

    @Test func testSyncTransactionsPath() {
        #expect(MoneyManagerEndpoint.syncTransactions(limit: 100, offset: 0).path == "/transactions")
    }

    @Test func testSyncTransactionsQueryParams() {
        let params = MoneyManagerEndpoint.syncTransactions(limit: 50, offset: 10).queryParameters
        #expect(params?["limit"] == "50")
        #expect(params?["offset"] == "10")
        #expect(params?["is_deleted"] == "false")
    }

    @Test func testNonTransactionEndpointHasNilQueryParams() {
        #expect(MoneyManagerEndpoint.me.queryParameters == nil)
        #expect(MoneyManagerEndpoint.groups.queryParameters == nil)
    }

    // MARK: - Group paths

    @Test func testGroupsPath() {
        #expect(MoneyManagerEndpoint.groups.path == "/groups")
    }

    @Test func testGroupPath() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        #expect(MoneyManagerEndpoint.group(id).path == "/groups/00000000-0000-0000-0000-000000000001")
    }

    @Test func testGroupMembersPath() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        #expect(MoneyManagerEndpoint.groupMembers(id).path == "/groups/00000000-0000-0000-0000-000000000002/members")
    }

    @Test func testGroupTransactionPath() {
        let gid = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let tid = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
        let expected = "/groups/00000000-0000-0000-0000-000000000003/transactions/00000000-0000-0000-0000-000000000004"
        #expect(MoneyManagerEndpoint.groupTransaction(groupId: gid, transactionId: tid).path == expected)
    }

    @Test func testSettlementsPath() {
        #expect(MoneyManagerEndpoint.settlements.path == "/settlements")
    }

    // MARK: - Raw path

    @Test func testRawPathPassthrough() {
        #expect(MoneyManagerEndpoint.raw("/transactions/abc").path == "/transactions/abc")
    }

    // MARK: - baseURL

    @Test func testBaseURLUsesHTTPS() {
        let url = MoneyManagerEndpoint.me.baseURL
        #expect(url.scheme == "https")
    }
}

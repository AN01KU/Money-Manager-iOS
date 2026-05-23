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

    // MARK: - Remaining sync paths

    @Test func testSyncCategoriesPath() {
        #expect(MoneyManagerEndpoint.syncCategories.path == "/categories")
    }

    @Test func testSyncBudgetsPath() {
        #expect(MoneyManagerEndpoint.syncBudgets.path == "/budgets")
    }

    @Test func testSyncRecurringPath() {
        #expect(MoneyManagerEndpoint.syncRecurring.path == "/recurring-transactions")
    }

    // MARK: - Remaining group paths

    @Test func testGroupAddMemberPath() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
        #expect(MoneyManagerEndpoint.groupAddMember(id).path == "/groups/00000000-0000-0000-0000-000000000005/members")
    }

    @Test func testGroupBalancesPath() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000006")!
        #expect(MoneyManagerEndpoint.groupBalances(id).path == "/groups/00000000-0000-0000-0000-000000000006/balances")
    }

    @Test func testGroupTransactionsPath() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000007")!
        #expect(MoneyManagerEndpoint.groupTransactions(id).path == "/groups/00000000-0000-0000-0000-000000000007/transactions")
    }

    // MARK: - Raw path

    @Test func testRawPathPassthrough() {
        #expect(MoneyManagerEndpoint.raw("/transactions/abc").path == "/transactions/abc")
    }

    // MARK: - baseURL

    @Test func testBaseURLIsValid() {
        let url = MoneyManagerEndpoint.me.baseURL
        #expect(url.scheme == "https" || url.scheme == "http")
        #expect(!(url.host ?? "").isEmpty)
    }

    // MARK: - requiresAuth

    @Test func testLoginDoesNotRequireAuth() {
        #expect(MoneyManagerEndpoint.login.requiresAuth == false)
    }

    @Test func testSignupDoesNotRequireAuth() {
        #expect(MoneyManagerEndpoint.signup.requiresAuth == false)
    }

    @Test func testHealthDoesNotRequireAuth() {
        #expect(MoneyManagerEndpoint.health.requiresAuth == false)
    }

    @Test func testLogoutRequiresAuth() {
        #expect(MoneyManagerEndpoint.logout.requiresAuth == true)
    }

    @Test func testVerifyEmailRequiresAuth() {
        #expect(MoneyManagerEndpoint.verifyEmail.requiresAuth == true)
    }

    @Test func testResendVerificationRequiresAuth() {
        #expect(MoneyManagerEndpoint.resendVerification.requiresAuth == true)
    }

    @Test func testMeRequiresAuth() {
        #expect(MoneyManagerEndpoint.me.requiresAuth == true)
    }

    @Test func testUpdateMeRequiresAuth() {
        #expect(MoneyManagerEndpoint.updateMe.requiresAuth == true)
    }

    @Test func testSyncPreflightRequiresAuth() {
        #expect(MoneyManagerEndpoint.syncPreflight.requiresAuth == true)
    }

    @Test func testPredefinedCategoriesRequiresAuth() {
        #expect(MoneyManagerEndpoint.predefinedCategories.requiresAuth == true)
    }

    @Test func testSyncCategoriesRequiresAuth() {
        #expect(MoneyManagerEndpoint.syncCategories.requiresAuth == true)
    }

    @Test func testSyncBudgetsRequiresAuth() {
        #expect(MoneyManagerEndpoint.syncBudgets.requiresAuth == true)
    }

    @Test func testGetBudgetRequiresAuth() {
        #expect(MoneyManagerEndpoint.getBudget.requiresAuth == true)
    }

    @Test func testSetBudgetRequiresAuth() {
        #expect(MoneyManagerEndpoint.setBudget.requiresAuth == true)
    }

    @Test func testSyncRecurringRequiresAuth() {
        #expect(MoneyManagerEndpoint.syncRecurring.requiresAuth == true)
    }

    @Test func testSyncTransactionsRequiresAuth() {
        #expect(MoneyManagerEndpoint.syncTransactions(limit: 10, offset: 0).requiresAuth == true)
    }

    @Test func testGroupsRequiresAuth() {
        #expect(MoneyManagerEndpoint.groups.requiresAuth == true)
    }

    @Test func testGroupRequiresAuth() {
        #expect(MoneyManagerEndpoint.group(UUID()).requiresAuth == true)
    }

    @Test func testGroupMembersRequiresAuth() {
        #expect(MoneyManagerEndpoint.groupMembers(UUID()).requiresAuth == true)
    }

    @Test func testGroupMemberRequiresAuth() {
        #expect(MoneyManagerEndpoint.groupMember(groupId: UUID(), userId: UUID()).requiresAuth == true)
    }

    @Test func testGroupAddMemberRequiresAuth() {
        #expect(MoneyManagerEndpoint.groupAddMember(UUID()).requiresAuth == true)
    }

    @Test func testGroupLeaveRequiresAuth() {
        #expect(MoneyManagerEndpoint.groupLeave(UUID()).requiresAuth == true)
    }

    @Test func testGroupBalancesRequiresAuth() {
        #expect(MoneyManagerEndpoint.groupBalances(UUID()).requiresAuth == true)
    }

    @Test func testGroupTransactionsRequiresAuth() {
        #expect(MoneyManagerEndpoint.groupTransactions(UUID()).requiresAuth == true)
    }

    @Test func testGroupTransactionRequiresAuth() {
        #expect(MoneyManagerEndpoint.groupTransaction(groupId: UUID(), transactionId: UUID()).requiresAuth == true)
    }

    @Test func testSettlementsRequiresAuth() {
        #expect(MoneyManagerEndpoint.settlements.requiresAuth == true)
    }

    @Test func testSettlementRequiresAuth() {
        #expect(MoneyManagerEndpoint.settlement(UUID()).requiresAuth == true)
    }

    @Test func testRawRequiresAuth() {
        #expect(MoneyManagerEndpoint.raw("/transactions/abc").requiresAuth == true)
    }

    // MARK: - requiresSyncSession

    @Test func testLoginDoesNotRequireSyncSession() {
        #expect(MoneyManagerEndpoint.login.requiresSyncSession == false)
    }

    @Test func testSignupDoesNotRequireSyncSession() {
        #expect(MoneyManagerEndpoint.signup.requiresSyncSession == false)
    }

    @Test func testLogoutDoesNotRequireSyncSession() {
        #expect(MoneyManagerEndpoint.logout.requiresSyncSession == false)
    }

    @Test func testVerifyEmailDoesNotRequireSyncSession() {
        #expect(MoneyManagerEndpoint.verifyEmail.requiresSyncSession == false)
    }

    @Test func testResendVerificationDoesNotRequireSyncSession() {
        #expect(MoneyManagerEndpoint.resendVerification.requiresSyncSession == false)
    }

    @Test func testHealthDoesNotRequireSyncSession() {
        #expect(MoneyManagerEndpoint.health.requiresSyncSession == false)
    }

    @Test func testSyncCategoriesRequiresSyncSession() {
        #expect(MoneyManagerEndpoint.syncCategories.requiresSyncSession == true)
    }

    @Test func testSyncTransactionsRequiresSyncSession() {
        #expect(MoneyManagerEndpoint.syncTransactions(limit: 10, offset: 0).requiresSyncSession == true)
    }

    @Test func testGroupsRequiresSyncSession() {
        #expect(MoneyManagerEndpoint.groups.requiresSyncSession == true)
    }

    @Test func testRawRequiresSyncSession() {
        #expect(MoneyManagerEndpoint.raw("/transactions/abc").requiresSyncSession == true)
    }
}

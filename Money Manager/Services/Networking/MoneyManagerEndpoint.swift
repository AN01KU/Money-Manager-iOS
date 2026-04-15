import APIClient
import Foundation

enum MoneyManagerEndpoint: BaseAPI.APIEndpoint {

    // MARK: - Auth
    case me
    case login
    case signup
    case logout
    case health

    // MARK: - Sync
    case syncPreflight
    case syncCategories
    case syncBudgets
    case syncRecurring
    /// Paginated transaction fetch. `limit` and `offset` are passed as query parameters.
    case syncTransactions(limit: Int, offset: Int)

    // MARK: - Groups
    case groups
    case group(UUID)
    case groupMembers(UUID)
    case groupAddMember(UUID)
    case groupBalances(UUID)
    case groupTransactions(UUID)
    case groupTransaction(groupId: UUID, transactionId: UUID)
    case settlements

    // MARK: - Raw path escape (used by ChangeQueueManager replay)
    /// Allows the change-queue replay to use dynamically-built paths that cannot
    /// be expressed as typed cases (e.g. "/transactions/<uuid>").
    case raw(String)

    // MARK: - APIEndpoint

    var baseURL: URL {
        let host = Bundle.main.object(forInfoDictionaryKey: "API_BASE_HOST") as? String ?? ""
        return URL(string: "https://\(host)")!
    }

    var path: String {
        switch self {
        case .me:                           return "/me"
        case .login:                        return "/auth/login"
        case .signup:                       return "/auth/signup"
        case .logout:                       return "/auth/logout"
        case .health:                       return "/health"
        case .syncPreflight:                return "/sync/preflight"
        case .syncCategories:               return "/categories"
        case .syncBudgets:                  return "/budgets"
        case .syncRecurring:                return "/recurring-transactions"
        case .syncTransactions:             return "/transactions"
        case .groups:                       return "/groups"
        case .group(let id):                return "/groups/\(id.uuidString)"
        case .groupMembers(let id):         return "/groups/\(id.uuidString)/members"
        case .groupAddMember(let id):       return "/groups/\(id.uuidString)/add-member"
        case .groupBalances(let id):        return "/groups/\(id.uuidString)/balances"
        case .groupTransactions(let id):    return "/groups/\(id.uuidString)/transactions"
        case .groupTransaction(let gid, let tid):
            return "/groups/\(gid.uuidString)/transactions/\(tid.uuidString)"
        case .settlements:                  return "/settlements"
        case .raw(let path):                return path
        }
    }

    var queryParameters: [String: String]? {
        switch self {
        case .syncTransactions(let limit, let offset):
            return [
                "limit": "\(limit)",
                "offset": "\(offset)",
                "is_deleted": "false"
            ]
        default:
            return nil
        }
    }
}

import APIClient
import Foundation

/// Injects `X-Sync-Session-ID` and `X-Sync-Version: 1` on write requests (POST/PUT/PATCH/DELETE)
/// that are NOT auth-management or health endpoints.
struct SyncSessionInterceptor: BaseAPI.RequestInterceptor {
    private static let writeMethods: Set<String> = ["POST", "PUT", "PATCH", "DELETE"]
    private static let syncExemptPaths: Set<String> = Set(
        [MoneyManagerEndpoint.login, .signup, .logout, .verifyEmail, .resendVerification, .health]
            .map(\.path)
    )

    func adapt(_ request: URLRequest) async throws -> URLRequest {
        guard let method = request.httpMethod,
              Self.writeMethods.contains(method) else {
            return request
        }
        guard let path = request.url?.path, !Self.syncExemptPaths.contains(path) else {
            return request
        }
        #if DEBUG
        let syncSessionID: UUID?
        if let override = AppAPIClient.testSyncSessionIDOverride {
            syncSessionID = override
        } else {
            syncSessionID = await SessionStore.shared.getSyncSessionID()
        }
        #else
        let syncSessionID = await SessionStore.shared.getSyncSessionID()
        #endif
        guard let syncSessionID else {
            return request
        }
        var modified = request
        modified.setValue(syncSessionID.uuidString, forHTTPHeaderField: HTTPHeaderName.syncSessionID.rawValue)
        modified.setValue("1", forHTTPHeaderField: HTTPHeaderName.syncVersion.rawValue)
        return modified
    }
}

import APIClient
import Foundation

/// Injects `X-Sync-Session-ID` and `X-Sync-Version: 1` on write requests (POST/PUT/PATCH/DELETE)
/// that are NOT auth endpoints.
struct SyncSessionInterceptor: BaseAPI.RequestInterceptor {
    private static let writeMethods: Set<String> = ["POST", "PUT", "PATCH", "DELETE"]

    func adapt(_ request: URLRequest) async throws -> URLRequest {
        guard let method = request.httpMethod,
              Self.writeMethods.contains(method) else {
            return request
        }
        guard let path = request.url?.path, !path.hasPrefix("/auth/") else {
            return request
        }
        guard let syncSessionID = await SessionStore.shared.getSyncSessionID() else {
            return request
        }
        var modified = request
        modified.setValue(syncSessionID.uuidString, forHTTPHeaderField: "X-Sync-Session-ID")
        modified.setValue("1", forHTTPHeaderField: "X-Sync-Version")
        return modified
    }
}

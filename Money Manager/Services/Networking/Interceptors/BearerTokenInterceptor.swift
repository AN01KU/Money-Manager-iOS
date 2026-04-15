import APIClient
import Foundation

/// Injects `Authorization: Bearer <token>` on every request that is NOT an auth endpoint.
///
/// Auth endpoints (`/auth/*`) are skipped to avoid sending a stale token on login/signup.
struct BearerTokenInterceptor: BaseAPI.RequestInterceptor {
    func adapt(_ request: URLRequest) async throws -> URLRequest {
        guard let path = request.url?.path, !path.hasPrefix("/auth/") else {
            return request
        }
        #if DEBUG
        let token: String?
        if let override = AppAPIClient.testTokenOverride {
            token = override
        } else {
            token = await SessionStore.shared.getToken()
        }
        #else
        let token = await SessionStore.shared.getToken()
        #endif
        guard let token else { return request }
        var modified = request
        modified.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return modified
    }
}

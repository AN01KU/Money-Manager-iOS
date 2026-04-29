import APIClient
import Foundation

/// Injects `Authorization: Bearer <token>` on every request except public auth endpoints.
///
/// Only `/auth/login` and `/auth/signup` are skipped — other `/auth/*` paths like
/// `/auth/verify-email`, `/auth/logout`, and `/auth/resend-verification` are protected
/// routes that require a valid token.
struct BearerTokenInterceptor: BaseAPI.RequestInterceptor {
    private static let publicPaths: Set<String> = ["/auth/login", "/auth/signup"]

    func adapt(_ request: URLRequest) async throws -> URLRequest {
        guard let path = request.url?.path, !Self.publicPaths.contains(path) else {
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

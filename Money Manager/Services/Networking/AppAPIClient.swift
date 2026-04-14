import APIClient
import Foundation

/// App-level HTTP client. Wraps `BaseAPI.BaseAPIClient<MoneyManagerEndpoint>` with:
/// - Millisecond-epoch date encoding/decoding
/// - Bearer token injection via `BearerTokenInterceptor`
/// - Sync-session header injection via `SyncSessionInterceptor`
/// - App-specific error mapping via `MoneyManagerResponseValidator`
/// - `authSessionExpired` notification on 401
final class AppAPIClient: Sendable {
    static let shared = AppAPIClient()

    let client: BaseAPI.BaseAPIClient<MoneyManagerEndpoint>
    private let decoder: JSONDecoder

    /// Shared encoder configured with millisecond-epoch date strategy.
    /// Used by `SyncService.enqueueLocalData` when pre-serialising payloads.
    static let apiEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(Int64(date.timeIntervalSince1970 * 1000))
        }
        return encoder
    }()

    private convenience init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.API.defaultTimeout
        config.timeoutIntervalForResource = AppConstants.API.defaultTimeout
        self.init(sessionConfiguration: config)
    }

    init(sessionConfiguration: URLSessionConfiguration) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(Int64(date.timeIntervalSince1970 * 1000))
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let ms = try container.decode(Int64.self)
            return Date(timeIntervalSince1970: Double(ms) / 1000.0)
        }

        self.decoder = decoder
        client = BaseAPI.BaseAPIClient<MoneyManagerEndpoint>(
            sessionConfiguration: sessionConfiguration,
            encoder: encoder,
            decoder: decoder,
            interceptors: [
                BearerTokenInterceptor(),
                SyncSessionInterceptor()
            ],
            validators: [MoneyManagerResponseValidator()],
            unauthorizedHandler: { _ in
                Task { @MainActor in
                    NotificationCenter.default.post(name: .authSessionExpired, object: nil)
                }
            }
        )
    }

    // MARK: - GET

    func get<T: Decodable>(_ endpoint: MoneyManagerEndpoint) async throws -> T {
        let (data, _) = try await client.get(endpoint) as BaseAPI.APIResponse<T>
        return data
    }

    // MARK: - POST

    func post<Req: Encodable, Res: Decodable>(
        _ endpoint: MoneyManagerEndpoint,
        body: sending Req
    ) async throws -> Res {
        let (data, _) = try await client.post(endpoint, body: body) as BaseAPI.APIResponse<Res>
        return data
    }

    func post<T: Decodable>(
        _ endpoint: MoneyManagerEndpoint,
        rawBody: Data
    ) async throws -> T {
        let (data, _): BaseAPI.APIResponse<T> = try await client.post(endpoint, rawBody: rawBody)
        return data
    }

    // MARK: - PUT

    func put<Req: Encodable, Res: Decodable>(
        _ endpoint: MoneyManagerEndpoint,
        body: sending Req
    ) async throws -> Res {
        let (data, _): BaseAPI.APIResponse<Res> = try await client
            .request(endpoint)
            .method(.put)
            .body(body)
            .response()
        return data
    }

    func put<T: Decodable>(
        _ endpoint: MoneyManagerEndpoint,
        rawBody: Data
    ) async throws -> T {
        let (data, _): BaseAPI.APIResponse<T> = try await client.put(endpoint, rawBody: rawBody)
        return data
    }

    // MARK: - PATCH

    func patch<Req: Encodable, Res: Decodable>(
        _ endpoint: MoneyManagerEndpoint,
        body: sending Req
    ) async throws -> Res {
        let (data, _): BaseAPI.APIResponse<Res> = try await client
            .request(endpoint)
            .method(.patch)
            .body(body)
            .response()
        return data
    }

    func patch<T: Decodable>(
        _ endpoint: MoneyManagerEndpoint,
        rawBody: Data
    ) async throws -> T {
        let (data, _): BaseAPI.APIResponse<T> = try await client.patch(endpoint, rawBody: rawBody)
        return data
    }

    // MARK: - DELETE

    func delete(_ endpoint: MoneyManagerEndpoint) async throws {
        _ = try await client.delete(endpoint) as HTTPURLResponse
    }

    func deleteMessage(_ endpoint: MoneyManagerEndpoint) async throws -> APIMessageResponse {
        let (rawData, _) = try await client
            .request(endpoint)
            .method(.delete)
            .responseData()
        return try decoder.decode(APIMessageResponse.self, from: rawData)
    }

    // MARK: - Ping

    func ping() async -> Bool {
        do {
            let (_, response) = try await client.request(.health).responseData()
            return (200...299).contains(response.statusCode)
        } catch {
            return false
        }
    }

    // MARK: - Debug test helpers

    #if DEBUG
    @MainActor
    func setTestToken(_ token: String?) {
        if let token {
            SessionStore.shared.saveToken(token)
        } else {
            SessionStore.shared.clearSession()
        }
    }

    @MainActor
    func setTestSyncSessionID(_ id: UUID?) {
        if let id {
            SessionStore.shared.saveSyncSessionID(id)
        }
    }

    #endif
}


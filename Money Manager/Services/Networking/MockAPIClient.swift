//
//  MockAPIClient.swift
//  Money Manager
//

#if DEBUG
import Foundation

/// Thread-safe mock for `APIClientProtocol`.
///
/// Usage in tests:
/// ```swift
/// let mock = MockAPIClient()
/// mock.getHandler = { endpoint in
///     return APIListResponse(data: [...])
/// }
/// ```
///
/// All handlers default to throwing `MockAPIClient.Error.notConfigured` so
/// tests must opt in to each call they expect — unexpected calls fail loudly.
final class MockAPIClient: APIClientProtocol, @unchecked Sendable {

    enum MockError: Error {
        case notConfigured
    }

    // MARK: - Call recording

    private(set) var getCalls: [MoneyManagerEndpoint] = []
    private(set) var postCalls: [(endpoint: MoneyManagerEndpoint, body: Data?)] = []
    private(set) var putCalls: [(endpoint: MoneyManagerEndpoint, body: Data?)] = []
    private(set) var patchCalls: [(endpoint: MoneyManagerEndpoint, body: Data?)] = []
    private(set) var deleteCalls: [MoneyManagerEndpoint] = []
    private(set) var deleteMessageCalls: [MoneyManagerEndpoint] = []

    // MARK: - Stubs

    /// Called by `get<T>`. Cast the returned value to `T`.
    var getHandler: ((MoneyManagerEndpoint) throws -> Any)?
    /// Called by typed-body `post<Req,Res>`. Return value is cast to `Res`.
    var postHandler: ((MoneyManagerEndpoint, Data?) throws -> Any)?
    /// Called by raw-body `post<T>`. Return value is cast to `T`.
    var rawPostHandler: ((MoneyManagerEndpoint, Data) throws -> Any)?
    /// Called by `put<T>`.
    var rawPutHandler: ((MoneyManagerEndpoint, Data) throws -> Any)?
    /// Called by `patch<T>`.
    var rawPatchHandler: ((MoneyManagerEndpoint, Data) throws -> Any)?
    /// Called by `delete`.
    var deleteHandler: ((MoneyManagerEndpoint) throws -> Void)?
    /// Called by `deleteMessage`.
    var deleteMessageHandler: ((MoneyManagerEndpoint) throws -> APIMessageResponse)?
    /// Return value for `ping`.
    var pingResult: Bool = true

    // MARK: - APIClientProtocol

    func get<T: Decodable>(_ endpoint: MoneyManagerEndpoint) async throws -> T {
        getCalls.append(endpoint)
        guard let handler = getHandler else { throw MockError.notConfigured }
        let raw = try handler(endpoint)
        guard let value = raw as? T else {
            throw MockError.notConfigured
        }
        return value
    }

    func post<Req: Encodable, Res: Decodable>(
        _ endpoint: MoneyManagerEndpoint, body: sending Req
    ) async throws -> Res {
        let data = try? JSONEncoder().encode(body)
        postCalls.append((endpoint: endpoint, body: data))
        guard let handler = postHandler else { throw MockError.notConfigured }
        let raw = try handler(endpoint, data)
        guard let value = raw as? Res else { throw MockError.notConfigured }
        return value
    }

    func post<T: Decodable>(
        _ endpoint: MoneyManagerEndpoint, rawBody: Data
    ) async throws -> T {
        postCalls.append((endpoint: endpoint, body: rawBody))
        guard let handler = rawPostHandler else { throw MockError.notConfigured }
        let raw = try handler(endpoint, rawBody)
        guard let value = raw as? T else { throw MockError.notConfigured }
        return value
    }

    func put<T: Decodable>(
        _ endpoint: MoneyManagerEndpoint, rawBody: Data
    ) async throws -> T {
        putCalls.append((endpoint: endpoint, body: rawBody))
        guard let handler = rawPutHandler else { throw MockError.notConfigured }
        let raw = try handler(endpoint, rawBody)
        guard let value = raw as? T else { throw MockError.notConfigured }
        return value
    }

    func patch<T: Decodable>(
        _ endpoint: MoneyManagerEndpoint, rawBody: Data
    ) async throws -> T {
        patchCalls.append((endpoint: endpoint, body: rawBody))
        guard let handler = rawPatchHandler else { throw MockError.notConfigured }
        let raw = try handler(endpoint, rawBody)
        guard let value = raw as? T else { throw MockError.notConfigured }
        return value
    }

    func delete(_ endpoint: MoneyManagerEndpoint) async throws {
        deleteCalls.append(endpoint)
        try deleteHandler?(endpoint)
    }

    func deleteMessage(_ endpoint: MoneyManagerEndpoint) async throws -> APIMessageResponse {
        deleteMessageCalls.append(endpoint)
        guard let handler = deleteMessageHandler else { throw MockError.notConfigured }
        return try handler(endpoint)
    }

    func ping() async -> Bool { pingResult }
}
#endif

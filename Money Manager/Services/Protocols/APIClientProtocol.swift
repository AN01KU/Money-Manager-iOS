//
//  APIClientProtocol.swift
//  Money Manager
//

import Foundation

/// Abstraction over AppAPIClient so services can be tested without live HTTP calls.
protocol APIClientProtocol: Sendable {
    func get<T: Decodable>(_ endpoint: MoneyManagerEndpoint) async throws -> T
    func post<Req: Encodable, Res: Decodable>(
        _ endpoint: MoneyManagerEndpoint, body: sending Req
    ) async throws -> Res
    func post<T: Decodable>(
        _ endpoint: MoneyManagerEndpoint, rawBody: Data
    ) async throws -> T
    func put<T: Decodable>(
        _ endpoint: MoneyManagerEndpoint, rawBody: Data
    ) async throws -> T
    func patch<T: Decodable>(
        _ endpoint: MoneyManagerEndpoint, rawBody: Data
    ) async throws -> T
    func delete(_ endpoint: MoneyManagerEndpoint) async throws
    func deleteMessage(_ endpoint: MoneyManagerEndpoint) async throws -> APIMessageResponse
    func ping() async -> Bool
}

extension AppAPIClient: APIClientProtocol {}

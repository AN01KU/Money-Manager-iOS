//
//  APICommon.swift
//  Money Manager
//

import Foundation

struct APIPaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let pagination: APIPagination
}

struct APIListResponse<T: Codable>: Codable {
    let data: [T]
}

struct APIPagination: Codable, Sendable {
    let limit: Int
    let offset: Int
    let total: Int
}

struct APIMessageResponse: Codable, Sendable {
    let message: String
}

/// Decodes successfully regardless of response body shape.
/// Used when only success (2xx) matters, not the response payload.
struct EmptyResponse: Codable, Sendable {
    init() {}
    init(from decoder: Decoder) throws {}
}

/// Encodes as an empty JSON object `{}`.
/// Use as the request body type when an endpoint takes no parameters.
struct EmptyBody: Codable, Sendable {
    init() {}
}

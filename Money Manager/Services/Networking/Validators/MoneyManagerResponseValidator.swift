import APIClient
import Foundation

/// Validates HTTP responses and maps non-2xx status codes to the app's `APIError` type.
///
/// Reuses `APIError.init(from:data:)` so all status-code-to-error mapping lives in one place.
struct MoneyManagerResponseValidator: BaseAPI.ResponseValidator {
    func validate(_ response: HTTPURLResponse, data: Data, for request: URLRequest) throws {
        guard !(200...299).contains(response.statusCode) else { return }
        throw APIError(from: response, data: data)
    }
}

import Foundation

@MainActor
final class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    func logError(_ error: Error, context: String = "") {
        let contextLabel = context.isEmpty ? "" : " [\(context)]"
        print("❌ ERROR\(contextLabel): \(error.localizedDescription)")
    }
}

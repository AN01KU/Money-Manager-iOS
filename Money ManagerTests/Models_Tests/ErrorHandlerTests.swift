import Foundation
import Testing
@testable import Money_Manager

struct ErrorHandlerTests {
    
    @Test
    func singletonInstanceExists() {
        let handler = ErrorHandler.shared
        #expect(handler === ErrorHandler.shared)
    }
    
    @Test
    func logErrorDoesNotThrow() {
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        ErrorHandler.shared.logError(error)
    }
    
    @Test
    func logErrorWithContextDoesNotThrow() {
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        ErrorHandler.shared.logError(error, context: "TestContext")
    }
}

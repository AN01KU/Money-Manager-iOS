import Foundation
import Testing
@testable import Money_Manager

struct ErrorHandlerTests {
    
    @Test
    func testAPIErrorInvalidURLErrorDescription() {
        let error = APIError.invalidURL
        
        #expect(error.errorDescription == "Invalid URL configuration")
    }
    
    @Test
    func testAPIErrorUnauthorizedErrorDescription() {
        let error = APIError.unauthorized
        
        #expect(error.errorDescription == "Session expired. Please log in again.")
    }
    
    @Test
    func testAPIErrorBadRequestWithMessage() {
        let error = APIError.badRequest("Invalid email format")
        
        #expect(error.errorDescription == "Invalid email format")
    }
    
    @Test
    func testAPIErrorServerErrorWithCode() {
        let error = APIError.serverError(500)
        
        #expect(error.errorDescription == "Server error (500). Please try again later.")
    }
    
    @Test
    func testAPIErrorServerErrorWithDifferentCodes() {
        #expect(APIError.serverError(404).errorDescription?.contains("404") == true)
        #expect(APIError.serverError(503).errorDescription?.contains("503") == true)
    }
    
    @Test
    func testAPIErrorDecodingErrorDescription() {
        let error = APIError.decodingError
        
        #expect(error.errorDescription == "Failed to process server response")
    }
    
    @Test
    func testAPIErrorTimeoutDescription() {
        let error = APIError.timeout
        
        #expect(error.errorDescription == "Request timeout. Please check your connection.")
    }
    
    @Test
    func testAPIErrorNetworkErrorContainsUnderlyingError() {
        let underlyingError = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection refused"])
        let error = APIError.networkError(underlyingError)
        
        #expect(error.errorDescription?.contains("Connection refused") == true)
    }
    
    @Test
    func testErrorHandlerIsNetworkErrorDetectsNetworkErrors() {
        let error = APIError.networkError(NSError(domain: "test", code: -1))
        let result = ErrorHandler.shared.isNetworkError(error)
        
        #expect(result == true)
    }
    
    @Test
    func testErrorHandlerIsNetworkErrorRejectsNonNetworkErrors() {
        let error = APIError.unauthorized
        let result = ErrorHandler.shared.isNetworkError(error)
        
        #expect(result == false)
    }
    
    @Test
    func testErrorHandlerIsAuthErrorDetectsUnauthorized() {
        let error = APIError.unauthorized
        let result = ErrorHandler.shared.isAuthError(error)
        
        #expect(result == true)
    }
    
    @Test
    func testErrorHandlerIsAuthErrorRejectsNonAuthErrors() {
        let error = APIError.serverError(500)
        let result = ErrorHandler.shared.isAuthError(error)
        
        #expect(result == false)
    }
    
    @Test
    func testErrorHandlerGetUserFriendlyMessageForAPIError() {
        let error = APIError.badRequest("Email already exists")
        let message = ErrorHandler.shared.getUserFriendlyMessage(for: error)
        
        #expect(message == "Email already exists")
    }
    
    @Test
    func testErrorHandlerGetUserFriendlyMessageForGenericError() {
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
        let message = ErrorHandler.shared.getUserFriendlyMessage(for: error)
        
        #expect(message == "Something went wrong")
    }
}

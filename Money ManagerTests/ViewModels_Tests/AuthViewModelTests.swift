import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct AuthViewModelTests {
    
    @Test
    func testIsFormValidLoginWithValidCredentials() {
        let viewModel = AuthViewModel()
        viewModel.isLoginMode = true
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        #expect(viewModel.isFormValid == true)
    }
    
    @Test
    func testIsFormValidLoginWithInvalidEmail() {
        let viewModel = AuthViewModel()
        viewModel.isLoginMode = true
        viewModel.email = "invalid-email"
        viewModel.password = "password123"
        
        #expect(viewModel.isFormValid == false)
    }
    
    @Test
    func testIsFormValidLoginWithEmptyEmail() {
        let viewModel = AuthViewModel()
        viewModel.isLoginMode = true
        viewModel.email = ""
        viewModel.password = "password123"
        
        #expect(viewModel.isFormValid == false)
    }
    
    @Test
    func testIsFormValidLoginWithShortPassword() {
        let viewModel = AuthViewModel()
        viewModel.isLoginMode = true
        viewModel.email = "test@example.com"
        viewModel.password = "12345"
        
        #expect(viewModel.isFormValid == false)
    }
    
    @Test
    func testIsFormValidLoginWithExactMinPasswordLength() {
        let viewModel = AuthViewModel()
        viewModel.isLoginMode = true
        viewModel.email = "test@example.com"
        viewModel.password = "123456"
        
        #expect(viewModel.isFormValid == true)
    }
    
    @Test
    func testIsFormValidSignupWithMatchingPasswords() {
        let viewModel = AuthViewModel()
        viewModel.isLoginMode = false
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        
        #expect(viewModel.isFormValid == true)
    }
    
    @Test
    func testIsFormValidSignupWithMismatchingPasswords() {
        let viewModel = AuthViewModel()
        viewModel.isLoginMode = false
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "differentpassword"
        
        #expect(viewModel.isFormValid == false)
    }
    
    @Test
    func testIsFormValidSignupWithEmptyConfirmPassword() {
        let viewModel = AuthViewModel()
        viewModel.isLoginMode = false
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = ""
        
        #expect(viewModel.isFormValid == false)
    }
    
    @Test
    func testToggleModeSwitchesToSignup() {
        let viewModel = AuthViewModel()
        viewModel.isLoginMode = true
        viewModel.confirmPassword = "savedpassword"
        
        viewModel.toggleMode()
        
        #expect(viewModel.isLoginMode == false)
        #expect(viewModel.confirmPassword == "")
    }
    
    @Test
    func testToggleModeSwitchesToLogin() {
        let viewModel = AuthViewModel()
        viewModel.isLoginMode = false
        viewModel.confirmPassword = "savedpassword"
        
        viewModel.toggleMode()
        
        #expect(viewModel.isLoginMode == true)
        #expect(viewModel.confirmPassword == "")
    }
    
    @Test
    func testIsFormValidWithEmailWithoutAtSymbol() {
        let viewModel = AuthViewModel()
        viewModel.isLoginMode = true
        viewModel.email = "testexample.com"
        viewModel.password = "password123"
        
        #expect(viewModel.isFormValid == false)
    }
    
    @Test
    func testIsFormValidWithWhitespaceInEmail() {
        let viewModel = AuthViewModel()
        viewModel.isLoginMode = true
        viewModel.email = "  test@example.com  "
        viewModel.password = "password123"
        
        #expect(viewModel.isFormValid == true)
    }
}

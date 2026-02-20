import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct SplitModelsTests {
    
    @Test
    func testAuthRequestEncodingToSnakeCase() throws {
        let request = AuthRequest(email: "test@example.com", password: "password123")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("\"email\""))
        #expect(json.contains("\"password\""))
        #expect(!json.contains("\"email_address\""))
    }
    
    @Test
    func testCreateGroupRequestEncoding() throws {
        let request = CreateGroupRequest(name: "Goa Trip")
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("\"name\":\"Goa Trip\""))
    }
    
    @Test
    func testAddMemberRequestEncoding() throws {
        let request = AddMemberRequest(userEmail: "test@example.com")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("\"user_email\":\"test@example.com\""))
    }
    
    @Test
    func testCreateSharedExpenseRequestEncodingWithSnakeCase() throws {
        let groupId = UUID()
        let splits = [
            ExpenseSplit(userId: UUID(), amount: "100.00"),
            ExpenseSplit(userId: UUID(), amount: "100.00")
        ]
        let request = CreateSharedExpenseRequest(
            groupId: groupId,
            description: "Dinner",
            category: "Food & Dining",
            totalAmount: "200.00",
            splits: splits
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("\"group_id\""))
        #expect(json.contains("\"total_amount\""))
        #expect(json.contains("\"description\""))
    }
    
    @Test
    func testExpenseSplitEncoding() throws {
        let userId = UUID()
        let split = ExpenseSplit(userId: userId, amount: "500.00")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(split)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("\"user_id\""))
        #expect(json.contains("\"amount\":\"500.00\""))
    }
    
    @Test
    func testCreateSettlementRequestEncoding() throws {
        let request = CreateSettlementRequest(
            groupId: UUID(),
            fromUser: UUID(),
            toUser: UUID(),
            amount: "500.00"
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("\"group_id\""))
        #expect(json.contains("\"from_user\""))
        #expect(json.contains("\"to_user\""))
    }
    
    @Test
    func testSetBudgetRequestEncoding() throws {
        let request = SetBudgetRequest(amount: "50000", month: 2, year: 2026)
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("\"amount\":\"50000\""))
        #expect(json.contains("\"month\":2"))
        #expect(json.contains("\"year\":2026"))
    }
    
    @Test
    func testCreateCategoryRequestEncoding() throws {
        let request = CreateCategoryRequest(name: "Coffee", color: "#FF6B6B", icon: "cup.and.saucer")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("\"name\":\"Coffee\""))
        #expect(json.contains("\"color\":\"#FF6B6B\""))
        #expect(json.contains("\"icon\":\"cup.and.saucer\""))
    }
    
    @Test
    func testUpdateCategoryRequestEncodingWithOptionals() throws {
        let request = UpdateCategoryRequest(name: "New Name", color: nil, icon: nil)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("\"name\":\"New Name\""))
    }
    
    @Test
    func testCreatePersonalExpenseRequestEncoding() throws {
        let categoryId = UUID()
        let request = CreatePersonalExpenseRequest(
            categoryId: categoryId,
            amount: "500.00",
            description: "Lunch",
            notes: "With team",
            expenseDate: "2026-02-19"
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("\"category_id\""))
        #expect(json.contains("\"expense_date\":\"2026-02-19\""))
    }
    
    @Test
    func testPaginationDecodingFromSnakeCase() throws {
        let json = """
        {"limit": 20, "offset": 0, "total": 100}
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let pagination = try decoder.decode(Pagination.self, from: data)
        
        #expect(pagination.limit == 20)
        #expect(pagination.offset == 0)
        #expect(pagination.total == 100)
    }
    
    @Test
    func testHealthResponseDecoding() throws {
        let json = """
        {"status": "healthy", "database": "connected"}
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let response = try decoder.decode(HealthResponse.self, from: data)
        
        #expect(response.status == "healthy")
        #expect(response.database == "connected")
    }
    
    @Test
    func testMessageResponseDecoding() throws {
        let json = """
        {"message": "Group created successfully"}
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let response = try decoder.decode(MessageResponse.self, from: data)
        
        #expect(response.message == "Group created successfully")
    }
}

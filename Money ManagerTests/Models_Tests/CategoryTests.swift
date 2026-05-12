import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct CategoryModelTests {
    
    @Test
    func testCategoryDefaultsIsHiddenToFalse() {
        let category = Category(name: "Coffee", icon: "cup.and.saucer", color: "#FF6B6B")
        
        #expect(category.isHidden == false)
    }
    
    @Test
    func testCategoryGeneratesUniqueId() {
        let category1 = Category(name: "Test1", icon: "star", color: "#FF0000")
        let category2 = Category(name: "Test2", icon: "star", color: "#FF0000")
        
        #expect(category1.id != category2.id)
    }
    
    @Test
    func testCategoryWithEmptyName() {
        let category = Category(name: "", icon: "star", color: "#FF0000")
        
        #expect(category.name == "")
    }
    
    // MARK: - isDeletable
    
    @Test
    func isDeletableReturnsTrueForNonOtherCategory() {
        let category = Category(key: "food-dining", name: "Groceries", icon: "cart", color: "#FF0000", isPredefined: true, predefinedKey: "food-dining")
        #expect(category.isDeletable == true)
    }

    @Test
    func isDeletableReturnsFalseForOtherCategory() {
        let category = Category(key: "other", name: "Other", icon: "ellipsis.circle.fill", color: "#95A5A6", isPredefined: true, predefinedKey: "other")
        #expect(category.isDeletable == false)
    }

    @Test
    func isDeletableReturnsTrueForCategory() {
        let category = Category(name: "Pets", icon: "pawprint", color: "#FF0000")
        #expect(category.isDeletable == true)
    }
}

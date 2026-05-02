import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct CustomCategoryModelTests {
    
    @Test
    func testCustomCategoryDefaultsIsHiddenToFalse() {
        let category = CustomCategory(name: "Coffee", icon: "cup.and.saucer", color: "#FF6B6B")
        
        #expect(category.isHidden == false)
    }
    
    @Test
    func testCustomCategoryStoresAllProperties() {
        let category = CustomCategory(name: "Groceries", icon: "cart", color: "#4ECDC4")
        
        #expect(category.name == "Groceries")
        #expect(category.icon == "cart")
        #expect(category.color == "#4ECDC4")
    }
    
    @Test
    func testCustomCategoryGeneratesUniqueId() {
        let category1 = CustomCategory(name: "Test1", icon: "star", color: "#FF0000")
        let category2 = CustomCategory(name: "Test2", icon: "star", color: "#FF0000")
        
        #expect(category1.id != category2.id)
    }
    
    @Test
    func testCustomCategoryWithHexColorFormats() {
        let colors = ["#FF6B6B", "#4ECDC4", "#FFEAA7", "#45B7D1", "#FFFFFF", "#000000"]
        
        for color in colors {
            let category = CustomCategory(name: "Test", icon: "star", color: color)
            #expect(category.color == color)
        }
    }
    
    @Test
    func testCustomCategoryWithEmptyName() {
        let category = CustomCategory(name: "", icon: "star", color: "#FF0000")
        
        #expect(category.name == "")
    }
    
    // MARK: - isDeletable
    
    @Test
    func isDeletableReturnsTrueForNonOtherCategory() {
        let category = CustomCategory(key: "food-dining", name: "Groceries", icon: "cart", color: "#FF0000", isPredefined: true, predefinedKey: "food-dining")
        #expect(category.isDeletable == true)
    }

    @Test
    func isDeletableReturnsFalseForOtherCategory() {
        let category = CustomCategory(key: "other", name: "Other", icon: "ellipsis.circle.fill", color: "#95A5A6", isPredefined: true, predefinedKey: "other")
        #expect(category.isDeletable == false)
    }

    @Test
    func isDeletableReturnsTrueForCustomCategory() {
        let category = CustomCategory(name: "Pets", icon: "pawprint", color: "#FF0000")
        #expect(category.isDeletable == true)
    }
}

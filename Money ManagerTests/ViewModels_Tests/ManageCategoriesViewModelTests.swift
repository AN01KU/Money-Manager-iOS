import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct ManageCategoriesViewModelTests {
    
    @Test
    func testVisibleCategoriesFiltersOutHidden() {
        let viewModel = ManageCategoriesViewModel()
        
        let visible1 = CustomCategory(name: "Cat1", icon: "star", color: "#FF0000")
        let visible2 = CustomCategory(name: "Cat2", icon: "star", color: "#FF0000")
        let hidden = CustomCategory(name: "Hidden", icon: "star", color: "#FF0000")
        hidden.isHidden = true
        
        viewModel.configure(customCategories: [visible1, visible2, hidden], modelContext: nil)
        
        #expect(viewModel.visibleCategories.count == 2)
    }
    
    @Test
    func testHiddenCategoriesReturnsOnlyHidden() {
        let viewModel = ManageCategoriesViewModel()
        
        let visible = CustomCategory(name: "Visible", icon: "star", color: "#FF0000")
        let hidden1 = CustomCategory(name: "Hidden1", icon: "star", color: "#FF0000")
        let hidden2 = CustomCategory(name: "Hidden2", icon: "star", color: "#FF0000")
        hidden1.isHidden = true
        hidden2.isHidden = true
        
        viewModel.configure(customCategories: [visible, hidden1, hidden2], modelContext: nil)
        
        #expect(viewModel.hiddenCategories.count == 2)
    }
    
    @Test
    func testHideCategorySetsIsHiddenToTrue() {
        let viewModel = ManageCategoriesViewModel()
        
        let category = CustomCategory(name: "Test", icon: "star", color: "#FF0000")
        
        viewModel.configure(customCategories: [category], modelContext: nil)
        
        viewModel.hideCategory(at: 0)
        
        #expect(category.isHidden == true)
    }
    
    @Test
    func testHideCategoryDoesNothingForInvalidIndex() {
        let viewModel = ManageCategoriesViewModel()
        
        let category = CustomCategory(name: "Test", icon: "star", color: "#FF0000")
        
        viewModel.configure(customCategories: [category], modelContext: nil)
        
        viewModel.hideCategory(at: 5)
        
        #expect(category.isHidden == false)
    }
    
    @Test
    func testRestoreCategorySetsIsHiddenToFalse() {
        let viewModel = ManageCategoriesViewModel()
        
        let category = CustomCategory(name: "Test", icon: "star", color: "#FF0000")
        category.isHidden = true
        
        viewModel.configure(customCategories: [category], modelContext: nil)
        
        viewModel.restoreCategory(category)
        
        #expect(category.isHidden == false)
    }
}

@MainActor
struct AddCategoryViewModelTests {
    
    @Test
    func testIconOptionsContainsStandardIcons() {
        let viewModel = AddCategoryViewModel()
        
        #expect(viewModel.iconOptions.contains("tag.circle.fill"))
        #expect(viewModel.iconOptions.contains("cart.circle.fill"))
        #expect(viewModel.iconOptions.contains("star.circle.fill"))
    }
    
    @Test
    func testColorOptionsContainsStandardColors() {
        let viewModel = AddCategoryViewModel()
        
        #expect(viewModel.colorOptions.contains("#FF6B6B"))
        #expect(viewModel.colorOptions.contains("#4ECDC4"))
        #expect(viewModel.colorOptions.contains("#3498DB"))
    }
    
    @Test
    func testDefaultIconIsSet() {
        let viewModel = AddCategoryViewModel()
        
        #expect(viewModel.selectedIcon == "tag.circle.fill")
    }
    
    @Test
    func testDefaultColorIsSet() {
        let viewModel = AddCategoryViewModel()
        
        #expect(viewModel.selectedColor == "#4ECDC4")
    }
    
    @Test
    func testIconOptionsHasMultipleChoices() {
        let viewModel = AddCategoryViewModel()
        
        #expect(viewModel.iconOptions.count > 10)
    }
    
    @Test
    func testColorOptionsHasMultipleChoices() {
        let viewModel = AddCategoryViewModel()
        
        #expect(viewModel.colorOptions.count > 10)
    }
}

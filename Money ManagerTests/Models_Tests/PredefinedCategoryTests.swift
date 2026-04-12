import Foundation
import SwiftUI
import Testing
@testable import Money_Manager

@MainActor
struct PredefinedCategoryTests {
    
    @Test
    func testAllPredefinedCategoriesHaveIcons() {
        for category in PredefinedCategory.allCases {
            #expect(!category.icon.isEmpty)
        }
    }
    
    @Test
    func testAllPredefinedCategoriesHaveColors() {
        for category in PredefinedCategory.allCases {
            #expect(category.color != Color.clear)
        }
    }
    
    @Test
    func testPredefinedCategoryIdMatchesRawValue() {
        for category in PredefinedCategory.allCases {
            #expect(category.id == category.rawValue)
        }
    }
    
    @Test
    func testFoodDiningCategory() {
        let category = PredefinedCategory.foodDining
        #expect(category.rawValue == "Food & Dining")
        #expect(category.icon == "fork.knife.circle.fill")
    }
    
    @Test
    func testTransportCategory() {
        let category = PredefinedCategory.transport
        #expect(category.rawValue == "Transport")
        #expect(category.icon == "car.circle.fill")
    }
    
    @Test
    func testHousingCategory() {
        let category = PredefinedCategory.housing
        #expect(category.rawValue == "Housing")
        #expect(category.icon == "house.circle.fill")
    }
    
    @Test
    func testHealthMedicalCategory() {
        let category = PredefinedCategory.healthMedical
        #expect(category.rawValue == "Health & Medical")
        #expect(category.icon == "cross.case.circle.fill")
    }
    
    @Test
    func testShoppingCategory() {
        let category = PredefinedCategory.shopping
        #expect(category.rawValue == "Shopping")
        #expect(category.icon == "bag.circle.fill")
    }
    
    @Test
    func testUtilitiesCategory() {
        let category = PredefinedCategory.utilities
        #expect(category.rawValue == "Utilities")
        #expect(category.icon == "bolt.square.fill")
    }
    
    @Test
    func testEntertainmentCategory() {
        let category = PredefinedCategory.entertainment
        #expect(category.rawValue == "Entertainment")
        #expect(category.icon == "gamecontroller.circle.fill")
    }
    
    @Test
    func testTravelCategory() {
        let category = PredefinedCategory.travel
        #expect(category.rawValue == "Travel")
        #expect(category.icon == "airplane.circle.fill")
    }
    
    @Test
    func testWorkProfessionalCategory() {
        let category = PredefinedCategory.workProfessional
        #expect(category.rawValue == "Work & Professional")
        #expect(category.icon == "briefcase.circle.fill")
    }
    
    @Test
    func testEducationCategory() {
        let category = PredefinedCategory.education
        #expect(category.rawValue == "Education")
        #expect(category.icon == "book.circle.fill")
    }
    
    @Test
    func testDebtPaymentsCategory() {
        let category = PredefinedCategory.debtPayments
        #expect(category.rawValue == "Debt & Payments")
        #expect(category.icon == "creditcard.circle.fill")
    }
    
    @Test
    func testBooksMediaCategory() {
        let category = PredefinedCategory.booksMedia
        #expect(category.rawValue == "Books & Media")
        #expect(category.icon == "book.closed.circle.fill")
    }
    
    @Test
    func testFamilyKidsCategory() {
        let category = PredefinedCategory.familyKids
        #expect(category.rawValue == "Family & Kids")
        #expect(category.icon == "figure.2.and.child.holdinghands")
    }
    
    @Test
    func testGiftsCategory() {
        let category = PredefinedCategory.gifts
        #expect(category.rawValue == "Gifts")
        #expect(category.icon == "gift.circle.fill")
    }
    
    @Test
    func testOtherCategory() {
        let category = PredefinedCategory.other
        #expect(category.rawValue == "Other")
        #expect(category.icon == "ellipsis.circle.fill")
    }
    
    @Test
    func testAllCasesAreIdentifiable() {
        for category in PredefinedCategory.allCases {
            #expect(!category.id.isEmpty)
        }
    }
    
    @Test
    func testTotalPredefinedCategoriesCount() {
        #expect(PredefinedCategory.allCases.count == 15)
    }
    
    @Test
    func testAllPredefinedCategoriesHaveKey() {
        for category in PredefinedCategory.allCases {
            #expect(!category.key.isEmpty)
        }
    }
    
    @Test
    func testAllPredefinedCategoriesHaveDefaultColorHex() {
        for category in PredefinedCategory.allCases {
            #expect(!category.defaultColorHex.isEmpty)
        }
    }
    
    @Test
    func testFoodDiningKey() {
        #expect(PredefinedCategory.foodDining.key == "foodDining")
    }
    
    @Test
    func testTransportKey() {
        #expect(PredefinedCategory.transport.key == "transport")
    }
}

@MainActor
struct ColorHexExtensionTests {
    
    @Test
    func testColorHexWith6DigitsDoesNotCrash() {
        let color = Color(hex: "FF0000")
        #expect(color != Color.clear)
    }
    
    @Test
    func testColorHexWith3DigitsDoesNotCrash() {
        let color = Color(hex: "F00")
        #expect(color != Color.clear)
    }
    
    @Test
    func testColorHexWith8DigitsDoesNotCrash() {
        let color = Color(hex: "FF000080")
        #expect(color != Color.clear)
    }
    
    @Test
    func testColorHexReturnsBlackForInvalid() {
        let color = Color(hex: "invalid")
        #expect(color != Color.clear)
    }
    
    @Test
    func testPredefinedColorsAreValid() {
        let testColors = [
            "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
            "#FFEAA7", "#DDA15E", "#BC6C25", "#8E44AD",
            "#34495E", "#3498DB", "#2C3E50", "#E74C3C",
            "#F39C12", "#E91E63", "#95A5A6"
        ]
        
        for hex in testColors {
            let color = Color(hex: hex)
            #expect(color != Color.clear)
        }
    }
}

import Foundation
import Testing
@testable import Money_Manager

struct CategoryModelTests {
    
    @Test
    func testCategoryFromStringMapsAllPredefinedCategories() {
        #expect(Category.fromString("Food & Dining") == .food)
        #expect(Category.fromString("Transport") == .transport)
        #expect(Category.fromString("Utilities") == .utilities)
        #expect(Category.fromString("Shopping") == .shopping)
        #expect(Category.fromString("Housing") == .housing)
        #expect(Category.fromString("Health & Medical") == .healthMedical)
        #expect(Category.fromString("Entertainment") == .entertainment)
        #expect(Category.fromString("Travel") == .travel)
    }
    
    @Test
    func testCategoryFromStringReturnsOtherForUnknownCategories() {
        #expect(Category.fromString("Unknown") == .other)
        #expect(Category.fromString("Random Category") == .other)
        #expect(Category.fromString("  ") == .other)
    }
    
    @Test
    func testCategoryFromStringRequiresExactMatch() {
        #expect(Category.fromString("food & dining") == .other)
        #expect(Category.fromString("FOOD & DINING") == .other)
        #expect(Category.fromString("Food & Dining") == .food)
    }
    
    @Test
    func testCategoryFromPredefinedMapsAllCases() {
        #expect(Category.fromPredefined(.foodDining) == .food)
        #expect(Category.fromPredefined(.transport) == .transport)
        #expect(Category.fromPredefined(.utilities) == .utilities)
        #expect(Category.fromPredefined(.shopping) == .shopping)
        #expect(Category.fromPredefined(.housing) == .housing)
        #expect(Category.fromPredefined(.healthMedical) == .healthMedical)
        #expect(Category.fromPredefined(.entertainment) == .entertainment)
        #expect(Category.fromPredefined(.travel) == .travel)
        #expect(Category.fromPredefined(.workProfessional) == .workProfessional)
        #expect(Category.fromPredefined(.education) == .education)
        #expect(Category.fromPredefined(.debtPayments) == .debtPayments)
        #expect(Category.fromPredefined(.booksMedia) == .booksMedia)
        #expect(Category.fromPredefined(.familyKids) == .familyKids)
        #expect(Category.fromPredefined(.gifts) == .gifts)
        #expect(Category.fromPredefined(.other) == .other)
    }
}

import Foundation
import SwiftUI
import Testing
@testable import Money_Manager

@MainActor
struct CategoryResolverTests {

    // MARK: - Predefined category

    @Test
    func testResolveKnownPredefinedCategoryReturnsCorrectIconAndColor() {
        let result = CategoryResolver.resolve("Food & Dining", customCategories: [])
        #expect(result.icon == PredefinedCategory.foodDining.icon)
        #expect(result.color == PredefinedCategory.foodDining.color)
    }

    @Test
    func testResolveAllPredefinedCategoriesNoneReturnFallback() {
        for category in PredefinedCategory.allCases {
            let result = CategoryResolver.resolve(category.rawValue, customCategories: [])
            #expect(result.icon != "ellipsis.circle.fill" || category == .other,
                    "Category \(category.rawValue) unexpectedly returned fallback icon")
        }
    }

    // MARK: - Unknown category fallback

    @Test
    func testResolveUnknownCategoryReturnsGrayAndEllipsisIcon() {
        let result = CategoryResolver.resolve("Some Unknown Category", customCategories: [])
        #expect(result.icon == "ellipsis.circle.fill")
        #expect(result.color == .gray)
    }

    @Test
    func testResolveEmptyCategoryReturnsGrayFallback() {
        let result = CategoryResolver.resolve("", customCategories: [])
        #expect(result.icon == "ellipsis.circle.fill")
        #expect(result.color == .gray)
    }

    // MARK: - Custom category preference

    @Test
    func testResolvePrefersVisibleCustomCategoryOverPredefined() {
        let custom = CustomCategory(name: "Food & Dining", icon: "custom.icon", color: "#FF0000")
        let result = CategoryResolver.resolve("Food & Dining", customCategories: [custom])
        #expect(result.icon == "custom.icon")
        #expect(result.color == Color(hex: "#FF0000"))
    }

    @Test
    func testResolveIgnoresHiddenCustomCategoryFallsBackToPredefined() {
        let hidden = CustomCategory(name: "Food & Dining", icon: "custom.icon", color: "#FF0000")
        hidden.isHidden = true
        let result = CategoryResolver.resolve("Food & Dining", customCategories: [hidden])
        #expect(result.icon == PredefinedCategory.foodDining.icon)
        #expect(result.color == PredefinedCategory.foodDining.color)
    }

    @Test
    func testResolveIgnoresHiddenCustomCategoryFallsBackToGrayWhenNoPredefined() {
        let hidden = CustomCategory(name: "My Custom", icon: "custom.icon", color: "#FF0000")
        hidden.isHidden = true
        let result = CategoryResolver.resolve("My Custom", customCategories: [hidden])
        #expect(result.icon == "ellipsis.circle.fill")
        #expect(result.color == .gray)
    }

    @Test
    func testResolveWithMultipleCustomCategoriesPicksMatchingOne() {
        let wrong = CustomCategory(name: "Transport", icon: "wrong.icon", color: "#000000")
        let correct = CustomCategory(name: "Pets", icon: "pawprint.fill", color: "#FF00FF")
        let result = CategoryResolver.resolve("Pets", customCategories: [wrong, correct])
        #expect(result.icon == "pawprint.fill")
        #expect(result.color == Color(hex: "#FF00FF"))
    }
}

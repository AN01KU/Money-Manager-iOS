import Foundation
import SwiftUI
import Testing
@testable import Money_Manager

@MainActor
struct CategoryResolverTests {

    // MARK: - Predefined category (resolved by server key)

    @Test
    func testResolveKnownPredefinedCategoryReturnsCorrectIconAndColor() {
        let result = CategoryResolver.resolve("food-dining", customCategories: [])
        #expect(result.icon == PredefinedCategory.foodDining.icon)
        #expect(result.color == PredefinedCategory.foodDining.color)
    }

    @Test
    func testResolveAllPredefinedCategoriesNoneReturnGray() {
        for category in PredefinedCategory.allCases {
            let result = CategoryResolver.resolve(category.serverKey, customCategories: [])
            #expect(result.color != .gray,
                    "Category \(category.serverKey) unexpectedly returned gray fallback color")
        }
    }

    // MARK: - Unknown category fallback

    @Test
    func testResolveUnknownCategoryReturnsGrayAndMiscIcon() {
        let result = CategoryResolver.resolve("totally-unknown-key", customCategories: [])
        #expect(result.icon == AppIcons.Category.other)
        #expect(result.color == .gray)
    }

    @Test
    func testResolveEmptyCategoryReturnsGrayFallback() {
        let result = CategoryResolver.resolve("", customCategories: [])
        #expect(result.icon == AppIcons.Category.other)
        #expect(result.color == .gray)
    }

    // MARK: - Custom category preference

    @Test
    func testResolvePrefersVisibleCustomCategoryOverPredefined() {
        let custom = CustomCategory(key: "food-dining", name: "Food & Dining", icon: "custom.icon", color: "#FF0000")
        let result = CategoryResolver.resolve("food-dining", customCategories: [custom])
        #expect(result.icon == "custom.icon")
        #expect(result.color == Color(hex: "#FF0000"))
    }

    @Test
    func testResolveIgnoresHiddenCustomCategoryFallsBackToPredefined() {
        let hidden = CustomCategory(key: "food-dining", name: "Food & Dining", icon: "custom.icon", color: "#FF0000")
        hidden.isHidden = true
        let result = CategoryResolver.resolve("food-dining", customCategories: [hidden])
        #expect(result.icon == PredefinedCategory.foodDining.icon)
        #expect(result.color == PredefinedCategory.foodDining.color)
    }

    @Test
    func testResolveIgnoresHiddenCustomCategoryFallsBackToGrayWhenNoPredefined() {
        let hidden = CustomCategory(key: "my-custom", name: "My Custom", icon: "custom.icon", color: "#FF0000")
        hidden.isHidden = true
        let result = CategoryResolver.resolve("my-custom", customCategories: [hidden])
        #expect(result.icon == AppIcons.Category.other)
        #expect(result.color == .gray)
    }

    @Test
    func testResolveWithMultipleCustomCategoriesPicksMatchingOne() {
        let wrong = CustomCategory(key: "transport", name: "Transport", icon: "wrong.icon", color: "#000000")
        let correct = CustomCategory(key: "pets", name: "Pets", icon: "pawprint.fill", color: "#FF00FF")
        let result = CategoryResolver.resolve("pets", customCategories: [wrong, correct])
        #expect(result.icon == "pawprint.fill")
        #expect(result.color == Color(hex: "#FF00FF"))
    }

    // MARK: - Lookup-based resolve (O(1) path)

    @Test
    func testResolveLookupMatchesConvenienceOverload() {
        let custom = CustomCategory(key: "food-dining", name: "Food & Dining", icon: "fork.knife", color: "#AABBCC")
        let lookup = CategoryResolver.makeLookup(from: [custom])
        let fast = CategoryResolver.resolve("food-dining", lookup: lookup)
        let slow = CategoryResolver.resolve("food-dining", customCategories: [custom])
        #expect(fast.icon == slow.icon)
        #expect(fast.color == slow.color)
    }

    @Test
    func testMakeLookupExcludesHiddenCategories() {
        let hidden = CustomCategory(key: "hidden-key", name: "Hidden", icon: "eye.slash", color: "#000000")
        hidden.isHidden = true
        let visible = CustomCategory(key: "visible-key", name: "Visible", icon: "eye", color: "#FFFFFF")
        let lookup = CategoryResolver.makeLookup(from: [hidden, visible])
        #expect(lookup["hidden-key"] == nil)
        #expect(lookup["visible-key"] != nil)
    }

    @Test
    func testResolveLookupFallsBackToPredefinedWhenNotInLookup() {
        let lookup = CategoryResolver.makeLookup(from: [])
        let result = CategoryResolver.resolve("food-dining", lookup: lookup)
        #expect(result.icon == PredefinedCategory.foodDining.icon)
    }

    @Test
    func testResolveLookupReturnsDefaultForUnknownCategory() {
        let lookup = CategoryResolver.makeLookup(from: [])
        let result = CategoryResolver.resolve("unknown-xyz", lookup: lookup)
        #expect(result.icon == AppIcons.Category.other)
        #expect(result.color == .gray)
    }
}

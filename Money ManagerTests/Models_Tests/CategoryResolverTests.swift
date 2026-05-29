import Foundation
import SwiftUI
import Testing
@testable import Money_Manager

@MainActor
struct CategoryResolverTests {

    // MARK: - UUID-based resolve

    @Test
    func testResolveKnownUUIDReturnsCorrectIconAndColor() {
        let catId = UUID()
        let cat = Category(id: catId, name: "Food", icon: "fork.knife", color: "#FF0000")
        let lookup = CategoryResolver.makeLookup(from: [cat])
        let result = CategoryResolver.resolve(catId, lookup: lookup)
        #expect(result.icon == "fork.knife")
        #expect(result.color == Color(hex: "#FF0000"))
    }

    @Test
    func testResolveUnknownUUIDReturnsGrayFallback() {
        let lookup = CategoryResolver.makeLookup(from: [])
        let result = CategoryResolver.resolve(UUID(), lookup: lookup)
        #expect(result.icon == AppIcons.Category.other)
        #expect(result.color == .gray)
    }

    @Test
    func testResolveAllKnownUUIDReturnsNameIconColor() {
        let catId = UUID()
        let cat = Category(id: catId, name: "Transport", icon: "car.fill", color: "#0000FF")
        let lookup = CategoryResolver.makeLookup(from: [cat])
        let result = CategoryResolver.resolveAll(catId, lookup: lookup)
        #expect(result.name == "Transport")
        #expect(result.icon == "car.fill")
    }

    @Test
    func testMakeLookupBuildsCorrectDictionary() {
        let id1 = UUID()
        let id2 = UUID()
        let cat1 = Category(id: id1, name: "Food", icon: "fork.knife", color: "#FF0000")
        let cat2 = Category(id: id2, name: "Transport", icon: "car.fill", color: "#0000FF")
        let lookup = CategoryResolver.makeLookup(from: [cat1, cat2])
        #expect(lookup[id1]?.name == "Food")
        #expect(lookup[id2]?.name == "Transport")
        #expect(lookup.count == 2)
    }

    @Test
    func testMakeLookupWithEmptyArrayReturnsEmptyDictionary() {
        let lookup = CategoryResolver.makeLookup(from: [])
        #expect(lookup.isEmpty)
    }

    @Test
    func testFindByKeyReturnsMatchingCategory() {
        let cat = Category(key: "food-dining", name: "Food & Dining", icon: "fork.knife", color: "#FF0000")
        let found = CategoryResolver.findByKey("food-dining", in: [cat])
        #expect(found?.name == "Food & Dining")
    }

    @Test
    func testFindByKeyReturnsNilForUnknownKey() {
        let cat = Category(key: "food-dining", name: "Food & Dining", icon: "fork.knife", color: "#FF0000")
        let found = CategoryResolver.findByKey("transport", in: [cat])
        #expect(found == nil)
    }

    @Test
    func testNameForIdReturnsCorrectName() {
        let catId = UUID()
        let cat = Category(id: catId, name: "Groceries", icon: "cart", color: "#00FF00")
        let name = CategoryResolver.name(for: catId, in: [cat])
        #expect(name == "Groceries")
    }

    @Test
    func testNameForUnknownIdReturnsOtherFallback() {
        let name = CategoryResolver.name(for: UUID(), in: [])
        #expect(name == AppIcons.Category.other)
    }

    // MARK: - Lookup-based resolve (O(1) path)

    @Test
    func testResolveLookupFallsBackToGrayForUnknownId() {
        let lookup = CategoryResolver.makeLookup(from: [])
        let result = CategoryResolver.resolve(UUID(), lookup: lookup)
        #expect(result.icon == AppIcons.Category.other)
        #expect(result.color == .gray)
    }

    @Test
    func testMakeLookupByKeyBuildsCorrectDictionary() {
        let cat = Category(key: "food-dining", name: "Food", icon: "fork.knife", color: "#FF0000", isPredefined: true, isServerPredefined: true)
        let lookup = CategoryResolver.makeLookupByKey(from: [cat])
        #expect(lookup["food-dining"]?.name == "Food")
    }
}

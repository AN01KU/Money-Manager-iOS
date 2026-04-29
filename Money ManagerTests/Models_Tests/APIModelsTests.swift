import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct APIModelsTests {

    // MARK: - APIGroup Equatable / Hashable

    @Test func testAPIGroupEqualityBasedOnId() {
        let id = UUID()
        let a = APIGroup(id: id, name: "Trip", createdBy: UUID(), createdAt: Date())
        let b = APIGroup(id: id, name: "Different Name", createdBy: UUID(), createdAt: Date())
        #expect(a == b)
    }

    @Test func testAPIGroupInequalityWhenDifferentIds() {
        let a = APIGroup(id: UUID(), name: "Trip", createdBy: UUID(), createdAt: Date())
        let b = APIGroup(id: UUID(), name: "Trip", createdBy: UUID(), createdAt: Date())
        #expect(a != b)
    }

    @Test func testAPIGroupHashConsistentWithEquality() {
        let id = UUID()
        let a = APIGroup(id: id, name: "Trip", createdBy: UUID(), createdAt: Date())
        let b = APIGroup(id: id, name: "Other", createdBy: UUID(), createdAt: Date())
        var set = Set<APIGroup>()
        set.insert(a)
        set.insert(b)
        // Same id → same hash → only one element in set
        #expect(set.count == 1)
    }

    // MARK: - APIGroupWithDetails Equatable / Hashable

    @Test func testAPIGroupWithDetailsEqualityBasedOnId() {
        let id = UUID()
        let a = APIGroupWithDetails(id: id, name: "Trip", createdBy: UUID(), createdAt: Date(), members: [], balances: [])
        let b = APIGroupWithDetails(id: id, name: "Other", createdBy: UUID(), createdAt: Date(), members: [], balances: [])
        #expect(a == b)
    }

    @Test func testAPIGroupWithDetailsInequalityWhenDifferentIds() {
        let a = APIGroupWithDetails(id: UUID(), name: "Trip", createdBy: UUID(), createdAt: Date(), members: [], balances: [])
        let b = APIGroupWithDetails(id: UUID(), name: "Trip", createdBy: UUID(), createdAt: Date(), members: [], balances: [])
        #expect(a != b)
    }

    @Test func testAPIGroupWithDetailsHashConsistentWithEquality() {
        let id = UUID()
        let a = APIGroupWithDetails(id: id, name: "Trip", createdBy: UUID(), createdAt: Date(), members: [], balances: [])
        let b = APIGroupWithDetails(id: id, name: "Other", createdBy: UUID(), createdAt: Date(), members: [], balances: [])
        var set = Set<APIGroupWithDetails>()
        set.insert(a)
        set.insert(b)
        #expect(set.count == 1)
    }

    // MARK: - EmptyResponse decoding

    @Test func testEmptyResponseDecodesFromAnyJSON() throws {
        let json = #"{"unexpected":"fields","are":"ignored"}"#.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(EmptyResponse.self, from: json)
        _ = response // Just verify it doesn't throw
    }

    @Test func testEmptyResponseDecodesFromEmptyObject() throws {
        let json = "{}".data(using: .utf8)!
        let decoder = JSONDecoder()
        _ = try decoder.decode(EmptyResponse.self, from: json)
    }

    @Test func testEmptyResponseDefaultInit() {
        let response = EmptyResponse()
        _ = response // Just verify it can be constructed
    }
}

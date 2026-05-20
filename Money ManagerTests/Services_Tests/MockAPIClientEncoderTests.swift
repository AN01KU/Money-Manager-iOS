import Foundation
import Testing
@testable import Money_Manager

/// Verifies that MockAPIClient encodes typed bodies with the same ms-epoch
/// date strategy as AppAPIClient, so test assertions on body Data match
/// what production sends over the wire.
@MainActor
struct MockAPIClientEncoderTests {

    private struct DatePayload: Encodable {
        let date: Date
    }

    private struct DatePayloadResponse: Decodable {}

    /// Returns the Int64 ms-epoch value embedded in the encoded body, or nil.
    private func extractMsEpoch(from data: Data?) -> Int64? {
        guard let data else { return nil }
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["date"] as? Int64
    }

    @Test
    func testPostTypedBodyUsesMillisecondEpoch() async throws {
        let mock = MockAPIClient()
        mock.postHandler = { _, _ in DatePayloadResponse() }

        let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
        let expectedMs = Int64(referenceDate.timeIntervalSince1970 * 1000)

        _ = try await mock.post(.health, body: DatePayload(date: referenceDate)) as DatePayloadResponse

        #expect(mock.postCalls.count == 1)
        let ms = extractMsEpoch(from: mock.postCalls[0].body)
        #expect(ms == expectedMs, "post body should use ms-epoch, got \(String(describing: ms))")
    }

    @Test
    func testPatchTypedBodyUsesMillisecondEpoch() async throws {
        let mock = MockAPIClient()
        mock.patchHandler = { _, _ in DatePayloadResponse() }

        let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
        let expectedMs = Int64(referenceDate.timeIntervalSince1970 * 1000)

        _ = try await mock.patch(.health, body: DatePayload(date: referenceDate)) as DatePayloadResponse

        #expect(mock.patchCalls.count == 1)
        let ms = extractMsEpoch(from: mock.patchCalls[0].body)
        #expect(ms == expectedMs, "patch body should use ms-epoch, got \(String(describing: ms))")
    }

    @Test
    func testPostBodyMatchesProductionWireFormat() async throws {
        let mock = MockAPIClient()
        mock.postHandler = { _, _ in DatePayloadResponse() }

        let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
        _ = try await mock.post(.health, body: DatePayload(date: referenceDate)) as DatePayloadResponse

        let productionData = try AppAPIClient.apiEncoder.encode(DatePayload(date: referenceDate))
        #expect(mock.postCalls[0].body == productionData,
                "mock post body must be byte-for-byte identical to production encoding")
    }
}

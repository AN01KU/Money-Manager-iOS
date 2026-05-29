import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct RetrySchedulerTests {

    private let fixedNow = Date(timeIntervalSinceReferenceDate: 1_000_000)

    private func makeScheduler(maxRetryCount: Int = 5, baseRetryDelay: TimeInterval = 2.0) -> RetryScheduler {
        RetryScheduler(maxRetryCount: maxRetryCount, baseRetryDelay: baseRetryDelay, now: { self.fixedNow })
    }

    // MARK: - nextRetryDate returns nil at maxRetryCount (dead-letter signal)

    @Test func testNextRetryDateReturnsNilAtMaxRetryCount() {
        let scheduler = makeScheduler(maxRetryCount: 5)
        #expect(scheduler.nextRetryDate(after: 5) == nil)
    }

    @Test func testNextRetryDateReturnsNilAboveMaxRetryCount() {
        let scheduler = makeScheduler(maxRetryCount: 5)
        #expect(scheduler.nextRetryDate(after: 10) == nil)
    }

    // MARK: - nextRetryDate returns a future date below maxRetryCount

    @Test func testNextRetryDateReturnsFutureDateForRetry0() {
        let scheduler = makeScheduler(maxRetryCount: 5, baseRetryDelay: 2.0)
        let result = scheduler.nextRetryDate(after: 0)
        #expect(result != nil)
        #expect(result! >= fixedNow.addingTimeInterval(2.0))
    }

    @Test func testNextRetryDateReturnsFutureDateForRetry4() {
        let scheduler = makeScheduler(maxRetryCount: 5, baseRetryDelay: 2.0)
        let result = scheduler.nextRetryDate(after: 4)
        #expect(result != nil)
        // 2 * 2^4 = 32s minimum
        #expect(result! >= fixedNow.addingTimeInterval(32.0))
    }

    // MARK: - Backoff curve doubles with each retry

    @Test func testNextRetryDateBackoffCurveDoubles() {
        // Use zero jitter by inspecting minimum bound: baseDelay * 2^n
        let scheduler = RetryScheduler(maxRetryCount: 6, baseRetryDelay: 2.0, now: { self.fixedNow })

        // Collect lower bounds for retries 0..4
        // base delay at retryCount n = 2 * 2^n
        for n in 0..<5 {
            let result = scheduler.nextRetryDate(after: n)!
            let expectedBase = 2.0 * pow(2.0, Double(n))
            #expect(result >= fixedNow.addingTimeInterval(expectedBase),
                    "retry \(n): expected >= \(expectedBase)s but got \(result.timeIntervalSince(fixedNow))s")
        }
    }

    // MARK: - Zero-delay scheduler for fast queue tests

    @Test func testZeroDelaySchedulerReturnsImmediateDate() {
        let scheduler = RetryScheduler(maxRetryCount: 5, baseRetryDelay: 0.0, now: { self.fixedNow })
        let result = scheduler.nextRetryDate(after: 0)
        #expect(result != nil)
        // With 0 base delay all jitter is 0; result is exactly fixedNow
        #expect(result! >= fixedNow)
        #expect(result! < fixedNow.addingTimeInterval(1.0))
    }

    // MARK: - Custom maxRetryCount

    @Test func testCustomMaxRetryCountIsRespected() {
        let scheduler = makeScheduler(maxRetryCount: 3)
        #expect(scheduler.nextRetryDate(after: 2) != nil)
        #expect(scheduler.nextRetryDate(after: 3) == nil)
    }

    // MARK: - Default init uses production values

    @Test func testDefaultInitHasProductionValues() {
        let scheduler = RetryScheduler()
        #expect(scheduler.maxRetryCount == 5)
        #expect(scheduler.baseRetryDelay == 2.0)
    }
}

//
//  RetryScheduler.swift
//  Money Manager
//

import Foundation

struct RetryScheduler: Sendable {
    let maxRetryCount: Int
    let baseRetryDelay: TimeInterval
    let now: @Sendable () -> Date

    init(
        maxRetryCount: Int = 5,
        baseRetryDelay: TimeInterval = 2.0,
        now: @Sendable @escaping () -> Date = { Date() }
    ) {
        self.maxRetryCount = maxRetryCount
        self.baseRetryDelay = baseRetryDelay
        self.now = now
    }

    /// Returns the next retry date using exponential backoff with random jitter,
    /// or nil if `retryCount` has reached `maxRetryCount` (dead-letter signal).
    /// Delays: ~2s, ~4s, ~8s, ~16s, ~32s for retries 1–5 with default settings.
    func nextRetryDate(after retryCount: Int) -> Date? {
        guard retryCount < maxRetryCount else { return nil }
        let exponent = min(retryCount, 10)
        let base = baseRetryDelay * pow(2.0, Double(exponent))
        let jitterRange = base * 0.2
        let jitter = jitterRange > 0 ? Double.random(in: 0..<jitterRange) : 0
        return now().addingTimeInterval(base + jitter)
    }
}

import Foundation

extension String {
    /// Returns true if the string is a plausible email address.
    /// Uses a simple regex that covers the vast majority of real-world addresses
    /// without requiring a network round-trip.
    var isValidEmail: Bool {
        let pattern = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }
}

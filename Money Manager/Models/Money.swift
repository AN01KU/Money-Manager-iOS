import Foundation

/// A locale-aware monetary value.
///
/// Stored as `Decimal` to avoid binary floating-point error and tagged with an ISO 4217 currency
/// code. Use `parse` to interpret user input (respects the user's decimal separator) and
/// `formatted` to render with the currency symbol. `editableString` produces a locale-neutral
/// string suitable for re-populating a `TextField`.
///
/// Scope note: `Transaction.amount` remains `Double` for now — Money is currently used for
/// parsing and formatting in transaction editor view models only.
struct Money: Equatable, Hashable, Sendable {
    nonisolated let amount: Decimal
    nonisolated let currencyCode: String

    nonisolated init(amount: Decimal, currencyCode: String) {
        self.amount = amount
        self.currencyCode = currencyCode
    }

    /// Parses user input as a non-negative `Money`. Returns `nil` for empty, non-numeric, or
    /// negative input.
    ///
    /// Locale is honored for the decimal separator — `"1,50"` parses in `de_DE` but not in
    /// `en_US`, and vice versa for `"1.50"`.
    nonisolated static func parse(_ input: String, currencyCode: String, locale: Locale = .current) -> Money? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        guard let decimal = Decimal(string: trimmed, locale: locale) else { return nil }
        guard decimal >= 0 else { return nil }
        return Money(amount: decimal, currencyCode: currencyCode)
    }

    /// Renders the amount with the currency symbol using the supplied locale (e.g. `"$100.50"`,
    /// `"100,00 €"`).
    nonisolated func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    /// Locale-neutral text for editable fields. Whole numbers render without a decimal portion
    /// (`100`); fractional values render with exactly two digits (`9.50`). Mirrors the
    /// `Double.editableString` contract.
    nonisolated var editableString: String {
        let doubleValue = (amount as NSDecimalNumber).doubleValue
        let isWhole = doubleValue.truncatingRemainder(dividingBy: 1) == 0
        return String(format: isWhole ? "%.0f" : "%.2f", doubleValue)
    }

    /// Convenience accessor for `Double`-typed call sites that haven't migrated yet.
    nonisolated var doubleValue: Double {
        (amount as NSDecimalNumber).doubleValue
    }
}

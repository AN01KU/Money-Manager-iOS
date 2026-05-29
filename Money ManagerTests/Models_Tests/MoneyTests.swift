import Foundation
import Testing
@testable import Money_Manager

struct MoneyTests {

    // MARK: - parse

    @Test func testParse_integer_USLocale() {
        let money = Money.parse("100", currencyCode: "USD", locale: Locale(identifier: "en_US"))
        #expect(money?.amount == Decimal(100))
        #expect(money?.currencyCode == "USD")
    }

    @Test func testParse_dotDecimal_USLocale() {
        let money = Money.parse("9.99", currencyCode: "USD", locale: Locale(identifier: "en_US"))
        #expect(money?.amount == Decimal(string: "9.99"))
    }

    @Test func testParse_commaDecimal_DELocale() {
        let money = Money.parse("1,50", currencyCode: "EUR", locale: Locale(identifier: "de_DE"))
        #expect(money?.amount == Decimal(string: "1.50"))
        #expect(money?.currencyCode == "EUR")
    }

    @Test func testParse_dotDecimal_DELocale_isRejected() {
        // In de_DE, "." is a grouping separator, not a decimal separator. "9.99" must not silently
        // parse as nine-point-ninety-nine.
        let money = Money.parse("9.99", currencyCode: "EUR", locale: Locale(identifier: "de_DE"))
        #expect(money?.amount != Decimal(string: "9.99"))
    }

    @Test func testParse_emptyString_isNil() {
        #expect(Money.parse("", currencyCode: "USD") == nil)
    }

    @Test func testParse_whitespaceOnly_isNil() {
        #expect(Money.parse("   ", currencyCode: "USD") == nil)
    }

    @Test func testParse_nonNumeric_isNil() {
        #expect(Money.parse("abc", currencyCode: "USD") == nil)
    }

    @Test func testParse_negative_isRejected() {
        #expect(Money.parse("-5", currencyCode: "USD", locale: Locale(identifier: "en_US")) == nil)
        #expect(Money.parse("-0.01", currencyCode: "USD", locale: Locale(identifier: "en_US")) == nil)
    }

    @Test func testParse_zero_isAccepted() {
        // Zero is a valid amount (e.g. a placeholder, or a refund equalling zero net).
        let money = Money.parse("0", currencyCode: "USD", locale: Locale(identifier: "en_US"))
        #expect(money?.amount == 0)
    }

    @Test func testParse_trimsSurroundingWhitespace() {
        let money = Money.parse("  42  ", currencyCode: "USD", locale: Locale(identifier: "en_US"))
        #expect(money?.amount == Decimal(42))
    }

    // MARK: - formatted

    @Test func testFormatted_USD_USLocale_includesDollarSignAndDecimals() {
        let money = Money(amount: Decimal(string: "100.50")!, currencyCode: "USD")
        let formatted = money.formatted(locale: Locale(identifier: "en_US"))
        #expect(formatted.contains("100.50"))
        #expect(formatted.contains("$"))
    }

    @Test func testFormatted_EUR_DELocale_usesCommaDecimal() {
        let money = Money(amount: Decimal(100), currencyCode: "EUR")
        let formatted = money.formatted(locale: Locale(identifier: "de_DE"))
        #expect(formatted.contains("100,00"))
        #expect(formatted.contains("€"))
    }

    // MARK: - editableString

    @Test func testEditableString_wholeNumber_hasNoDecimals() {
        #expect(Money(amount: Decimal(100), currencyCode: "USD").editableString == "100")
    }

    @Test func testEditableString_fractional_hasTwoDecimals() {
        let m = Money(amount: Decimal(string: "9.99")!, currencyCode: "USD")
        #expect(m.editableString == "9.99")
    }

    @Test func testEditableString_zero() {
        #expect(Money(amount: 0, currencyCode: "USD").editableString == "0")
    }

    @Test func testEditableString_singleFractionalDigit_padsToTwo() {
        let m = Money(amount: Decimal(string: "9.5")!, currencyCode: "USD")
        #expect(m.editableString == "9.50")
    }

    @Test func testEditableString_isLocaleNeutral() {
        // editableString feeds back into a TextField; it must use "." regardless of user locale
        // so re-parsing with the same locale-aware Money.parse round-trips cleanly.
        let m = Money(amount: Decimal(string: "1.50")!, currencyCode: "USD")
        #expect(m.editableString == "1.50")
    }
}

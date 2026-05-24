import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct CurrencyFormatterTests {

    // MARK: - Currency struct

    @Test
    func testCurrencyDefaultIsINR() {
        #expect(Currency.default.code == "INR")
        #expect(Currency.default.symbol == "₹")
        #expect(Currency.default.name == "Indian Rupee")
    }

    @Test
    func testCurrencyFindReturnsMatchingCurrency() {
        let usd = Currency.find(code: "USD")
        #expect(usd.code == "USD")
        #expect(usd.symbol == "$")
        #expect(usd.name == "US Dollar")
    }

    @Test
    func testCurrencyFindFallsBackToDefaultForUnknownCode() {
        let unknown = Currency.find(code: "XYZ")
        #expect(unknown == Currency.default)
    }

    @Test
    func testCurrencyAllContainsExpectedCodes() {
        let codes = Currency.all.map(\.code)
        #expect(codes.contains("INR"))
        #expect(codes.contains("USD"))
        #expect(codes.contains("EUR"))
        #expect(codes.contains("GBP"))
        #expect(codes.contains("JPY"))
    }

    @Test
    func testCurrencyAllHaveNonEmptyFields() {
        for currency in Currency.all {
            #expect(!currency.code.isEmpty)
            #expect(!currency.symbol.isEmpty)
            #expect(!currency.name.isEmpty)
        }
    }

    @Test
    func testCurrencyEquatable() {
        #expect(Currency.default == Currency.find(code: "INR"))
        #expect(Currency.find(code: "USD") != Currency.find(code: "EUR"))
    }

    // MARK: - CurrencyFormatter

    @Test
    func testSupportedCurrenciesIsCurrencyAll() {
        #expect(CurrencyFormatter.supportedCurrencies == Currency.all)
    }

    @Test
    func testCurrencySymbolsDerivedFromAll() {
        #expect(CurrencyFormatter.currencySymbols["USD"] == "$")
        #expect(CurrencyFormatter.currencySymbols["EUR"] == "€")
        #expect(CurrencyFormatter.currencySymbols["GBP"] == "£")
        #expect(CurrencyFormatter.currencySymbols["JPY"] == "¥")
    }

    @Test
    func testCurrentCodeDefaultsToINR() {
        let original = UserDefaults.standard.string(forKey: UserDefaults.Keys.selectedCurrency.rawValue)
        defer {
            if let original {
                UserDefaults.standard.set(original, forKey: UserDefaults.Keys.selectedCurrency.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.selectedCurrency.rawValue)
            }
        }
        UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.selectedCurrency.rawValue)

        #expect(CurrencyFormatter.currentCode == "INR")
    }

    @Test
    func testCurrentSymbolReturnsConfiguredCurrency() {
        #expect(!CurrencyFormatter.currentSymbol.isEmpty)
    }

    @Test
    func testCurrencyFormatterRoundsDecimalsWhenDisabled() {
        let formatted = CurrencyFormatter.format(1000.99, showDecimals: false)
        #expect(formatted.contains("1,001"))
    }

    @Test
    func testCurrencyFormatterShowsDecimalsWhenEnabled() {
        let formatted = CurrencyFormatter.format(1000.50, showDecimals: true)
        #expect(formatted.contains("50") || formatted.contains("0.50"))
    }

    @Test
    func testCurrencyFormatterHandlesZeroWithDecimals() {
        let formatted = CurrencyFormatter.format(0.00, showDecimals: true)
        #expect(formatted.contains("₹"))
    }

    @Test
    func testFormatNegativeAmount() {
        let formatted = CurrencyFormatter.format(-500.0, showDecimals: false)
        #expect(formatted.contains("500"))
    }

    @Test
    func testFormatLargeAmount() {
        let formatted = CurrencyFormatter.format(9999999, showDecimals: false)
        #expect(formatted.contains("9,999,999") || formatted.contains("99,99,999"))
    }

    @Test
    func testFormatUsesDefaultWithoutDecimalsParameter() {
        let formatted = CurrencyFormatter.format(100.50)
        #expect(formatted.contains("101") || formatted.contains("100"))
    }

    @Test
    func testFormatVerySmallAmount() {
        let formatted = CurrencyFormatter.format(0.01, showDecimals: true)
        #expect(formatted.contains("0.01") || formatted.contains(".01"))
    }

    @Test
    func testFormatWithoutSymbolFormatsLargeNumbers() {
        let formatted = CurrencyFormatter.formatWithoutSymbol(1234567)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let expected = formatter.string(from: NSNumber(value: 1234567)) ?? "1234567"
        #expect(formatted == expected)
    }

    @Test
    func testFormatWithoutSymbolHandlesZero() {
        #expect(CurrencyFormatter.formatWithoutSymbol(0) == "0")
    }

    @Test
    func testFormatWithoutSymbolWithLargeDecimal() {
        let formatted = CurrencyFormatter.formatWithoutSymbol(1234567)
        #expect(formatted.contains("1,234,567") || formatted.contains("12,34,567"))
    }
}

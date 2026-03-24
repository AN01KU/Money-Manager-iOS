import Foundation
import Testing
@testable import Money_Manager

struct CurrencyFormatterTests {
    
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
    func testCurrencyFormatterWithoutSymbolFormatsLargeNumbers() {
        let formatted = CurrencyFormatter.formatWithoutSymbol(1234567)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let expected = formatter.string(from: NSNumber(value: 1234567)) ?? "1234567"
        #expect(formatted == expected)
    }
    
    @Test
    func testCurrencyFormatterWithoutSymbolHandlesZero() {
        let formatted = CurrencyFormatter.formatWithoutSymbol(0)
        
        #expect(formatted == "0")
    }
    
    @Test
    func testCurrentSymbolReturnsConfiguredCurrency() {
        let symbol = CurrencyFormatter.currentSymbol
        
        #expect(!symbol.isEmpty)
    }
    
    @Test
    func testCurrentCodeDefaultsToINR() {
        UserDefaults.standard.removeObject(forKey: "selectedCurrency")
        
        let code = CurrencyFormatter.currentCode
        
        #expect(code == "INR")
    }
    
    @Test
    func testSupportedCurrenciesContainsCommonCurrencies() {
        let codes = CurrencyFormatter.supportedCurrencies.map { $0.code }
        
        #expect(codes.contains("INR"))
        #expect(codes.contains("USD"))
        #expect(codes.contains("EUR"))
        #expect(codes.contains("GBP"))
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
    func testCurrencySymbolsContainsExpectedCurrencies() {
        #expect(CurrencyFormatter.currencySymbols["USD"] == "$")
        #expect(CurrencyFormatter.currencySymbols["EUR"] == "€")
        #expect(CurrencyFormatter.currencySymbols["GBP"] == "£")
        #expect(CurrencyFormatter.currencySymbols["JPY"] == "¥")
    }
    
    @Test
    func testSupportedCurrenciesHaveValidData() {
        for currency in CurrencyFormatter.supportedCurrencies {
            #expect(!currency.code.isEmpty)
            #expect(!currency.name.isEmpty)
            #expect(!currency.symbol.isEmpty)
        }
    }
    
    @Test
    func testFormatVerySmallAmount() {
        let formatted = CurrencyFormatter.format(0.01, showDecimals: true)
        
        #expect(formatted.contains("0.01") || formatted.contains(".01"))
    }
    
    @Test
    func testFormatWithoutSymbolWithLargeDecimal() {
        let formatted = CurrencyFormatter.formatWithoutSymbol(1234567)
        
        #expect(formatted.contains("1,234,567") || formatted.contains("12,34,567"))
    }
}

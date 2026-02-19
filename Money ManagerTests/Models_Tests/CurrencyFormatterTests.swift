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
        
        #expect(formatted.contains("12,34,567"))
    }
    
    @Test
    func testCurrencyFormatterWithoutSymbolHandlesZero() {
        let formatted = CurrencyFormatter.formatWithoutSymbol(0)
        
        #expect(formatted == "0")
    }
}

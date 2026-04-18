import Testing
@testable import Money_Manager

struct DoubleEditableStringTests {

    @Test func testWholeNumberFormatsWithoutDecimal() {
        #expect((100.0).editableString == "100")
    }

    @Test func testFractionalNumberFormatsTwoDecimals() {
        #expect((9.99).editableString == "9.99")
    }

    @Test func testZeroFormatsAsZero() {
        #expect((0.0).editableString == "0")
    }

    @Test func testNegativeWholeNumber() {
        #expect((-50.0).editableString == "-50")
    }

    @Test func testNegativeFractionalNumber() {
        #expect((-9.5).editableString == "-9.50")
    }

    @Test func testLargeWholeNumber() {
        #expect((10000.0).editableString == "10000")
    }

    @Test func testSmallFractionalAmount() {
        #expect((0.01).editableString == "0.01")
    }
}

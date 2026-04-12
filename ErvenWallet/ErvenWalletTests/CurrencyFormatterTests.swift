import Testing
import Foundation
@testable import ErvenWallet

struct CurrencyFormatterTests {
    @Test func formatsZero() {
        let result = CurrencyFormatter.format(.zero)
        #expect(result.contains("0.00"))
        #expect(result.contains("₱"))
    }

    @Test func formatsWholeNumber() {
        let result = CurrencyFormatter.format(Decimal(1500))
        #expect(result.contains("1,500.00"))
    }

    @Test func formatsTwoDecimalPlaces() {
        let result = CurrencyFormatter.format(Decimal(string: "1234.56")!)
        #expect(result.contains("1,234.56"))
    }

    @Test func formatsNegative() {
        let result = CurrencyFormatter.format(Decimal(-250))
        #expect(result.contains("250"))
    }

    @Test func roundsToTwoDecimals() {
        let result = CurrencyFormatter.format(Decimal(string: "10.999")!)
        #expect(result.contains("11.00") || result.contains("10.99") || result.contains("11.0"))
    }

    @Test("Non-PHP currency still formats", arguments: ["USD", "EUR", "JPY"])
    func formatsOtherCurrency(code: String) {
        let result = CurrencyFormatter.format(Decimal(100), currency: code)
        #expect(!result.isEmpty)
    }
}

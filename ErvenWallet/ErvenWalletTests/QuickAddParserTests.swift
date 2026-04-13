import Testing
import Foundation
@testable import ErvenWallet

struct QuickAddParserTests {

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day; c.hour = 12
        return Calendar.current.date(from: c)!
    }

    @Test func parsesAmountOnly() {
        let draft = QuickAddParser.parse("250")
        #expect(draft.amount == 250)
        #expect(draft.type == .expense)
        #expect(draft.categoryName == nil)
    }

    @Test func parsesLunchAlias() {
        let draft = QuickAddParser.parse("lunch 250")
        #expect(draft.amount == 250)
        #expect(draft.categoryName == "food")
        #expect(draft.type == .expense)
    }

    @Test func parsesUberAlias() {
        let draft = QuickAddParser.parse("uber 120")
        #expect(draft.amount == 120)
        #expect(draft.categoryName == "transport")
    }

    @Test func parsesSalaryAsIncome() {
        let draft = QuickAddParser.parse("salary 50000")
        #expect(draft.amount == 50000)
        #expect(draft.type == .income)
        #expect(draft.categoryName == "salary")
    }

    @Test func parsesYesterday() {
        let today = date(2026, 4, 13)
        let draft = QuickAddParser.parse("coffee 150 yesterday", today: today)
        #expect(draft.amount == 150)
        #expect(draft.categoryName == "food")
        #expect(Calendar.current.isDate(draft.date, inSameDayAs: date(2026, 4, 12)))
    }

    @Test func parsesDecimalAmount() {
        let draft = QuickAddParser.parse("gas 1250.50")
        #expect(draft.amount == Decimal(string: "1250.50"))
        #expect(draft.categoryName == "transport")
    }

    @Test func leavesUnknownWordsAsNotes() {
        let draft = QuickAddParser.parse("lunch 250 with alice")
        #expect(draft.notes?.contains("with") == true)
        #expect(draft.notes?.contains("alice") == true)
    }

    @Test func handlesEmptyInput() {
        let draft = QuickAddParser.parse("")
        #expect(draft.amount == nil)
        #expect(draft.categoryName == nil)
    }

    @Test func firstNumberWinsForAmount() {
        let draft = QuickAddParser.parse("5 apples for 100")
        #expect(draft.amount == 5)
    }
}

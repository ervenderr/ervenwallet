import Testing
import Foundation
@testable import ErvenWallet

struct CreditCardMathTests {
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Manila")!
        return cal
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return calendar.date(from: components)!
    }

    // MARK: - statementPeriod

    @Test func statementPeriodBeforeStatementDay() {
        // statement day = 15, today = April 12 → period is March 15 → April 14
        let period = CreditCardMath.statementPeriod(
            containing: date(2026, 4, 12),
            statementDay: 15,
            calendar: calendar
        )
        #expect(period?.start == calendar.startOfDay(for: date(2026, 3, 15)))
        #expect(period?.end == calendar.startOfDay(for: date(2026, 4, 14)))
    }

    @Test func statementPeriodOnStatementDay() {
        // statement day = 15, today = April 15 → period just opened, April 15 → May 14
        let period = CreditCardMath.statementPeriod(
            containing: date(2026, 4, 15),
            statementDay: 15,
            calendar: calendar
        )
        #expect(period?.start == calendar.startOfDay(for: date(2026, 4, 15)))
        #expect(period?.end == calendar.startOfDay(for: date(2026, 5, 14)))
    }

    @Test func statementPeriodAfterStatementDay() {
        // statement day = 15, today = April 28 → period is April 15 → May 14
        let period = CreditCardMath.statementPeriod(
            containing: date(2026, 4, 28),
            statementDay: 15,
            calendar: calendar
        )
        #expect(period?.start == calendar.startOfDay(for: date(2026, 4, 15)))
        #expect(period?.end == calendar.startOfDay(for: date(2026, 5, 14)))
    }

    @Test func statementPeriodCrossingYearBoundary() {
        // statement day = 20, today = January 5, 2026 → period is Dec 20, 2025 → Jan 19, 2026
        let period = CreditCardMath.statementPeriod(
            containing: date(2026, 1, 5),
            statementDay: 20,
            calendar: calendar
        )
        #expect(period?.start == calendar.startOfDay(for: date(2025, 12, 20)))
        #expect(period?.end == calendar.startOfDay(for: date(2026, 1, 19)))
    }

    @Test func statementPeriodLeapYearFebruary() {
        // statement day = 28, today = Feb 28, 2024 (leap) → period is Feb 28 → March 27
        let period = CreditCardMath.statementPeriod(
            containing: date(2024, 2, 28),
            statementDay: 28,
            calendar: calendar
        )
        #expect(period?.start == calendar.startOfDay(for: date(2024, 2, 28)))
        #expect(period?.end == calendar.startOfDay(for: date(2024, 3, 27)))
    }

    @Test func statementPeriodInvalidDayReturnsNil() {
        #expect(CreditCardMath.statementPeriod(containing: Date(), statementDay: 0, calendar: calendar) == nil)
        #expect(CreditCardMath.statementPeriod(containing: Date(), statementDay: 29, calendar: calendar) == nil)
        #expect(CreditCardMath.statementPeriod(containing: Date(), statementDay: 31, calendar: calendar) == nil)
    }

    // MARK: - nextDueDate

    @Test func nextDueDateLaterThisMonth() {
        // due day = 5, today = April 1 → April 5
        let due = CreditCardMath.nextDueDate(asOf: date(2026, 4, 1), dueDay: 5, calendar: calendar)
        #expect(due == calendar.startOfDay(for: date(2026, 4, 5)))
    }

    @Test func nextDueDateOnDueDay() {
        // due day = 5, today = April 5 → April 5 (today)
        let due = CreditCardMath.nextDueDate(asOf: date(2026, 4, 5), dueDay: 5, calendar: calendar)
        #expect(due == calendar.startOfDay(for: date(2026, 4, 5)))
    }

    @Test func nextDueDateRollsToNextMonth() {
        // due day = 5, today = April 6 → May 5
        let due = CreditCardMath.nextDueDate(asOf: date(2026, 4, 6), dueDay: 5, calendar: calendar)
        #expect(due == calendar.startOfDay(for: date(2026, 5, 5)))
    }

    @Test func nextDueDateRollsToNextYear() {
        // due day = 10, today = December 15 → January 10 next year
        let due = CreditCardMath.nextDueDate(asOf: date(2026, 12, 15), dueDay: 10, calendar: calendar)
        #expect(due == calendar.startOfDay(for: date(2027, 1, 10)))
    }

    @Test func nextDueDateInvalidDayReturnsNil() {
        #expect(CreditCardMath.nextDueDate(asOf: Date(), dueDay: 0, calendar: calendar) == nil)
        #expect(CreditCardMath.nextDueDate(asOf: Date(), dueDay: 31, calendar: calendar) == nil)
    }

    // MARK: - daysUntilDue

    @Test func daysUntilDueCountsCorrectly() {
        // due day = 15, today = April 5 → 10 days
        let days = CreditCardMath.daysUntilDue(asOf: date(2026, 4, 5), dueDay: 15, calendar: calendar)
        #expect(days == 10)
    }

    @Test func daysUntilDueZeroOnDueDay() {
        let days = CreditCardMath.daysUntilDue(asOf: date(2026, 4, 15), dueDay: 15, calendar: calendar)
        #expect(days == 0)
    }

    // MARK: - availableCredit

    @Test func availableCreditNormal() {
        let available = CreditCardMath.availableCredit(creditLimit: 50000, currentBalance: 12000)
        #expect(available == 38000)
    }

    @Test func availableCreditOverLimit() {
        let available = CreditCardMath.availableCredit(creditLimit: 50000, currentBalance: 55000)
        #expect(available == -5000)
    }

    @Test func availableCreditAtZeroBalance() {
        let available = CreditCardMath.availableCredit(creditLimit: 30000, currentBalance: 0)
        #expect(available == 30000)
    }
}

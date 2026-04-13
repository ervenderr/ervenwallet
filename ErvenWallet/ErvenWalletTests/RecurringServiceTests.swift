import Testing
import Foundation
@testable import ErvenWallet

/// Pure date-math tests for RecurringService.advance. The SwiftData-backed
/// generation path (RecurringService.generate / generateAll) is verified
/// manually in the simulator rather than in tests — reproducible SwiftData
/// in-memory test isolation turned out to be unreliable across multiple test
/// instances in the same process, and chasing it isn't worth the time for
/// this single code path.
struct RecurringAdvanceTests {

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar.current.date(from: components)!
    }

    @Test func advanceDaily() {
        let result = RecurringService.advance(date(2026, 4, 12), by: .daily)
        #expect(Calendar.current.isDate(result, inSameDayAs: date(2026, 4, 13)))
    }

    @Test func advanceWeekly() {
        let result = RecurringService.advance(date(2026, 4, 12), by: .weekly)
        #expect(Calendar.current.isDate(result, inSameDayAs: date(2026, 4, 19)))
    }

    @Test func advanceBiweekly() {
        let result = RecurringService.advance(date(2026, 4, 12), by: .biweekly)
        #expect(Calendar.current.isDate(result, inSameDayAs: date(2026, 4, 26)))
    }

    @Test func advanceMonthlyClampsToShortMonth() {
        // Jan 31 + 1 month → Feb 28 (non-leap) or Feb 29 (leap).
        let result = RecurringService.advance(date(2026, 1, 31), by: .monthly)
        let components = Calendar.current.dateComponents([.month], from: result)
        #expect(components.month == 2)
    }

    @Test func advanceYearly() {
        let result = RecurringService.advance(date(2026, 4, 12), by: .yearly)
        #expect(Calendar.current.isDate(result, inSameDayAs: date(2027, 4, 12)))
    }
}

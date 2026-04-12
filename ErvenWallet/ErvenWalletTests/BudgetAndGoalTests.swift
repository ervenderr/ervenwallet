import Testing
import Foundation
import SwiftData
@testable import ErvenWallet

@MainActor
struct BudgetAndGoalTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        let schema = Schema([
            Account.self,
            TxnCategory.self,
            Transaction.self,
            Budget.self,
            SavingsGoal.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        self.container = try ModelContainer(for: schema, configurations: configuration)
    }

    // MARK: - Budget.normalize

    @Test func normalizeReturnsFirstOfMonth() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 15
        components.hour = 14
        components.minute = 30
        let mid = calendar.date(from: components)!

        let normalized = Budget.normalize(month: mid)
        let normalizedComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: normalized)
        #expect(normalizedComponents.year == 2026)
        #expect(normalizedComponents.month == 4)
        #expect(normalizedComponents.day == 1)
    }

    @Test func normalizeIsIdempotent() {
        let date = Date()
        let once = Budget.normalize(month: date)
        let twice = Budget.normalize(month: once)
        #expect(once == twice)
    }

    @Test func sameMonthNormalizesToSameValue() {
        let calendar = Calendar.current
        let day1 = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let day28 = calendar.date(from: DateComponents(year: 2026, month: 6, day: 28))!
        #expect(Budget.normalize(month: day1) == Budget.normalize(month: day28))
    }

    // MARK: - SavingsGoal computed properties

    @Test func progressIsZeroWhenNothingSaved() {
        let goal = SavingsGoal(name: "Fund", targetAmount: 1000)
        #expect(goal.progress == 0)
        #expect(goal.isComplete == false)
    }

    @Test func progressIsHalfAtFiftyPercent() {
        let goal = SavingsGoal(name: "Fund", targetAmount: 1000, currentAmount: 500)
        #expect(goal.progress == 0.5)
    }

    @Test func progressClampsAtOne() {
        let goal = SavingsGoal(name: "Fund", targetAmount: 1000, currentAmount: 5000)
        #expect(goal.progress == 1.0)
        #expect(goal.isComplete == true)
    }

    @Test func remainingNeverNegative() {
        let goal = SavingsGoal(name: "Fund", targetAmount: 1000, currentAmount: 1500)
        #expect(goal.remaining == 0)
    }

    @Test func remainingMatchesShortfall() {
        let goal = SavingsGoal(name: "Fund", targetAmount: 5000, currentAmount: 1200)
        #expect(goal.remaining == 3800)
    }

    @Test func dailyRequiredNilWithoutTargetDate() {
        let goal = SavingsGoal(name: "Fund", targetAmount: 1000, currentAmount: 0, targetDate: nil)
        #expect(goal.dailyRequired == nil)
    }

    @Test func dailyRequiredNilWhenComplete() {
        let goal = SavingsGoal(
            name: "Fund",
            targetAmount: 1000,
            currentAmount: 1000,
            targetDate: Date().addingTimeInterval(60 * 60 * 24 * 30)
        )
        #expect(goal.dailyRequired == nil)
    }

    @Test func dailyRequiredDividesRemainingByDays() {
        let tenDaysOut = Date().addingTimeInterval(60 * 60 * 24 * 10)
        let goal = SavingsGoal(
            name: "Fund",
            targetAmount: 1000,
            currentAmount: 0,
            targetDate: tenDaysOut
        )
        let daily = goal.dailyRequired ?? 0
        // 10 days, ₱1000 → ₱100/day (allow off-by-one for time-of-day rounding)
        #expect(daily >= 100 && daily <= 112)
    }
}

import Foundation

/// Pure date math for credit card statement cycles. Kept free of SwiftData
/// types so it can be unit-tested without a ModelContainer.
///
/// The model assumes `statementDay` and `dueDay` are clamped to 1...28 in the
/// UI so we never have to handle 29/30/31 month-end edge cases.
enum CreditCardMath {
    /// The statement period containing `date`, inclusive on both ends.
    /// `start` is the most recent occurrence of `statementDay` at-or-before
    /// `date`. `end` is the day before the next `statementDay`.
    static func statementPeriod(
        containing date: Date,
        statementDay: Int,
        calendar: Calendar = .current
    ) -> (start: Date, end: Date)? {
        guard (1...28).contains(statementDay) else { return nil }

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            return nil
        }

        let monthOffset = day >= statementDay ? 0 : -1
        guard
            let start = makeDate(year: year, month: month + monthOffset, day: statementDay, calendar: calendar),
            let nextStart = calendar.date(byAdding: .month, value: 1, to: start),
            let end = calendar.date(byAdding: .day, value: -1, to: nextStart)
        else {
            return nil
        }

        return (start: calendar.startOfDay(for: start), end: calendar.startOfDay(for: end))
    }

    /// Next occurrence of `dueDay` at-or-after `date`. If today's day-of-month
    /// equals `dueDay`, that counts as today.
    static func nextDueDate(
        asOf date: Date,
        dueDay: Int,
        calendar: Calendar = .current
    ) -> Date? {
        guard (1...28).contains(dueDay) else { return nil }

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            return nil
        }

        let monthOffset = day <= dueDay ? 0 : 1
        guard let due = makeDate(year: year, month: month + monthOffset, day: dueDay, calendar: calendar) else {
            return nil
        }
        return calendar.startOfDay(for: due)
    }

    /// Whole days until the next due date. Negative if today is past due
    /// (which shouldn't happen given `nextDueDate` rolls forward, but we
    /// guard anyway).
    static func daysUntilDue(
        asOf date: Date,
        dueDay: Int,
        calendar: Calendar = .current
    ) -> Int? {
        guard let due = nextDueDate(asOf: date, dueDay: dueDay, calendar: calendar) else {
            return nil
        }
        let startOfToday = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: startOfToday, to: due).day
    }

    /// Available credit on a card. Negative if over-limit.
    static func availableCredit(creditLimit: Decimal, currentBalance: Decimal) -> Decimal {
        creditLimit - currentBalance
    }

    /// Sum of expense amounts on the given account that fall within the
    /// statement period containing `date`.
    static func thisStatementSpend(
        transactions: [Transaction],
        accountID: UUID,
        statementDay: Int,
        asOf date: Date = Date(),
        calendar: Calendar = .current
    ) -> Decimal {
        guard let period = statementPeriod(
            containing: date,
            statementDay: statementDay,
            calendar: calendar
        ) else {
            return .zero
        }
        let exclusiveEnd = calendar.date(byAdding: .day, value: 1, to: period.end) ?? period.end

        var total: Decimal = .zero
        for txn in transactions {
            guard txn.type == .expense else { continue }
            guard txn.account?.id == accountID else { continue }
            guard txn.date >= period.start && txn.date < exclusiveEnd else { continue }
            total += txn.amount
        }
        return total
    }

    // MARK: - Private

    /// Build a Date from explicit y/m/d components, normalizing month overflow
    /// (e.g. month=13 → next year January, month=0 → previous year December).
    private static func makeDate(year: Int, month: Int, day: Int, calendar: Calendar) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)
    }
}

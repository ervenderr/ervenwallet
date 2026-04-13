import Foundation
import SwiftData

/// Materializes recurring rules into concrete `Transaction` records, advancing
/// each rule's `lastGeneratedDate` so re-running the generator is idempotent.
enum RecurringService {

    /// Generate any pending transactions for every rule, up to and including `date`.
    @MainActor
    static func generateAll(in context: ModelContext, upTo date: Date = Date()) {
        let descriptor = FetchDescriptor<RecurringRule>()
        guard let rules = try? context.fetch(descriptor) else { return }
        for rule in rules {
            generate(rule, in: context, upTo: date)
        }
    }

    /// Generate pending transactions for a single rule.
    @MainActor
    static func generate(_ rule: RecurringRule, in context: ModelContext, upTo date: Date) {
        var nextDate = rule.nextOccurrence
        let endOfDay = endOfDay(for: date)

        while nextDate <= endOfDay {
            if let endDate = rule.endDate, nextDate > endDate {
                return
            }
            let transaction = Transaction(
                amount: rule.amount,
                type: rule.type,
                account: rule.account,
                toAccount: rule.toAccount,
                category: rule.category,
                date: nextDate,
                notes: rule.notes
            )
            context.insert(transaction)
            transaction.applyToBalances()
            rule.lastGeneratedDate = nextDate
            nextDate = advance(nextDate, by: rule.frequency)
        }
    }

    /// Advance a date by one period of the given frequency. Pure function — no
    /// SwiftData dependency, kept here so the model can use it for `nextOccurrence`.
    static func advance(_ date: Date, by frequency: Frequency, calendar: Calendar = .current) -> Date {
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .day, value: 14, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }

    private static func endOfDay(for date: Date, calendar: Calendar = .current) -> Date {
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
        return calendar.date(byAdding: .second, value: -1, to: startOfNextDay) ?? date
    }
}

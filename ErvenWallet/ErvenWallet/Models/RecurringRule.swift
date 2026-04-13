import Foundation
import SwiftData

@Model
final class RecurringRule {
    var id: UUID = UUID()
    var amount: Decimal = Decimal.zero
    var typeRaw: String = TransactionType.expense.rawValue
    var frequencyRaw: String = Frequency.monthly.rawValue
    var startDate: Date = Date()
    var endDate: Date?
    var lastGeneratedDate: Date?
    var notes: String?
    var createdAt: Date = Date()

    var account: Account?
    var toAccount: Account?
    var category: TxnCategory?

    init(
        amount: Decimal,
        type: TransactionType,
        frequency: Frequency,
        account: Account?,
        toAccount: Account? = nil,
        category: TxnCategory? = nil,
        startDate: Date,
        endDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.typeRaw = type.rawValue
        self.frequencyRaw = frequency.rawValue
        self.account = account
        self.toAccount = toAccount
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.createdAt = Date()
    }

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    var frequency: Frequency {
        get { Frequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    /// The next date this rule should fire. If never generated, that's `startDate`;
    /// otherwise it's one period after the last generation.
    var nextOccurrence: Date {
        if let last = lastGeneratedDate {
            return RecurringService.advance(last, by: frequency)
        }
        return startDate
    }

    var displayLabel: String {
        if type == .transfer {
            let from = account?.name ?? "?"
            let to = toAccount?.name ?? "?"
            return "\(from) → \(to)"
        }
        return category?.name ?? "Uncategorized"
    }
}

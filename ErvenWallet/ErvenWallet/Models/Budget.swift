import Foundation
import SwiftData

@Model
final class Budget {
    var id: UUID = UUID()
    var amount: Decimal = Decimal.zero
    var month: Date = Date()
    var rollover: Bool = false
    var createdAt: Date = Date()

    var category: TxnCategory?

    init(
        category: TxnCategory,
        amount: Decimal,
        month: Date,
        rollover: Bool = false
    ) {
        self.id = UUID()
        self.category = category
        self.amount = amount
        self.month = Self.normalize(month: month)
        self.rollover = rollover
        self.createdAt = Date()
    }

    /// Snap to first second of the month so equality checks across the same calendar month succeed.
    static func normalize(month: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        return calendar.date(from: components) ?? month
    }
}

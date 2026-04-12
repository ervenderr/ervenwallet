import Foundation
import SwiftData

@Model
final class SavingsGoal {
    var id: UUID = UUID()
    var name: String = ""
    var targetAmount: Decimal = Decimal.zero
    var currentAmount: Decimal = Decimal.zero
    var targetDate: Date?
    var icon: String = "target"
    var colorHex: String = "#34C759"
    var createdAt: Date = Date()

    var linkedAccount: Account?

    init(
        name: String,
        targetAmount: Decimal,
        currentAmount: Decimal = .zero,
        targetDate: Date? = nil,
        icon: String = "target",
        colorHex: String = "#34C759",
        linkedAccount: Account? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
        self.icon = icon
        self.colorHex = colorHex
        self.linkedAccount = linkedAccount
        self.createdAt = Date()
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        let value = (currentAmount as NSDecimalNumber).doubleValue / (targetAmount as NSDecimalNumber).doubleValue
        return min(max(value, 0), 1)
    }

    var isComplete: Bool {
        currentAmount >= targetAmount
    }

    var remaining: Decimal {
        max(targetAmount - currentAmount, .zero)
    }

    /// Daily contribution required to hit the target by the target date.
    /// Returns nil if no target date set or already complete.
    var dailyRequired: Decimal? {
        guard let targetDate, !isComplete else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
        guard days > 0 else { return remaining }
        return remaining / Decimal(days)
    }
}

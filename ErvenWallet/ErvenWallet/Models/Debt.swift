import Foundation
import SwiftData

@Model
final class Debt {
    var id: UUID = UUID()
    var name: String = ""
    var directionRaw: String = DebtDirection.owed.rawValue
    var totalAmount: Decimal = Decimal.zero
    var remainingAmount: Decimal = Decimal.zero
    var interestRate: Decimal?
    var dueDate: Date?
    var notes: String?
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \DebtPayment.debt)
    var payments: [DebtPayment] = []

    init(
        name: String,
        direction: DebtDirection,
        totalAmount: Decimal,
        remainingAmount: Decimal? = nil,
        interestRate: Decimal? = nil,
        dueDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.directionRaw = direction.rawValue
        self.totalAmount = totalAmount
        self.remainingAmount = remainingAmount ?? totalAmount
        self.interestRate = interestRate
        self.dueDate = dueDate
        self.notes = notes
        self.createdAt = Date()
    }

    var direction: DebtDirection {
        get { DebtDirection(rawValue: directionRaw) ?? .owed }
        set { directionRaw = newValue.rawValue }
    }

    var paidAmount: Decimal {
        totalAmount - remainingAmount
    }

    var progress: Double {
        guard totalAmount > 0 else { return 0 }
        let value = (paidAmount as NSDecimalNumber).doubleValue / (totalAmount as NSDecimalNumber).doubleValue
        return min(max(value, 0), 1)
    }

    var isSettled: Bool {
        remainingAmount <= 0
    }
}

@Model
final class DebtPayment {
    var id: UUID = UUID()
    var amount: Decimal = Decimal.zero
    var date: Date = Date()
    var notes: String?

    var debt: Debt?

    init(amount: Decimal, date: Date = Date(), notes: String? = nil) {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.notes = notes
    }
}

enum DebtDirection: String, Codable, CaseIterable, Identifiable {
    case owed       // I owe someone (a liability)
    case owing      // Someone owes me (a receivable)

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .owed: "I Owe"
        case .owing: "Owed to Me"
        }
    }

    var systemImage: String {
        switch self {
        case .owed: "arrow.up.right.circle"
        case .owing: "arrow.down.left.circle"
        }
    }
}

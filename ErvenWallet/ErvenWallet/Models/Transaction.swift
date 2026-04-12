import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID = UUID()
    var amount: Decimal = Decimal.zero
    var typeRaw: String = TransactionType.expense.rawValue
    var date: Date = Date()
    var notes: String?
    var createdAt: Date = Date()

    var account: Account?
    var toAccount: Account?
    var category: Category?

    init(
        amount: Decimal,
        type: TransactionType,
        account: Account?,
        toAccount: Account? = nil,
        category: Category? = nil,
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.typeRaw = type.rawValue
        self.account = account
        self.toAccount = toAccount
        self.category = category
        self.date = date
        self.notes = notes
        self.createdAt = Date()
    }

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    /// Apply this transaction's effect to the linked account balances.
    /// Call once at insert time. Idempotency is the caller's responsibility.
    func applyToBalances() {
        switch type {
        case .expense:
            account?.balance -= amount
        case .income:
            account?.balance += amount
        case .transfer:
            account?.balance -= amount
            toAccount?.balance += amount
        }
    }

    /// Reverse the effect of this transaction. Call before deletion.
    func revertFromBalances() {
        switch type {
        case .expense:
            account?.balance += amount
        case .income:
            account?.balance -= amount
        case .transfer:
            account?.balance += amount
            toAccount?.balance -= amount
        }
    }
}

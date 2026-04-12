import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID = UUID()
    var name: String = ""
    var typeRaw: String = AccountType.cash.rawValue
    var balance: Decimal = Decimal.zero
    var currency: String = "PHP"
    var icon: String = "banknote"
    var colorHex: String = "#34C759"
    var createdAt: Date = Date()

    var creditLimit: Decimal?
    var statementDay: Int?
    var dueDay: Int?

    init(
        name: String,
        type: AccountType,
        balance: Decimal = .zero,
        currency: String = "PHP",
        icon: String? = nil,
        colorHex: String = "#34C759",
        creditLimit: Decimal? = nil,
        statementDay: Int? = nil,
        dueDay: Int? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.typeRaw = type.rawValue
        self.balance = balance
        self.currency = currency
        self.icon = icon ?? type.systemImage
        self.colorHex = colorHex
        self.createdAt = Date()
        self.creditLimit = creditLimit
        self.statementDay = statementDay
        self.dueDay = dueDay
    }

    var type: AccountType {
        get { AccountType(rawValue: typeRaw) ?? .cash }
        set { typeRaw = newValue.rawValue }
    }
}

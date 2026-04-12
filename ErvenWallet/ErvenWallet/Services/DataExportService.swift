import Foundation
import SwiftData

/// Versioned, schema-stable JSON export of all SwiftData content.
/// Bump `schemaVersion` whenever the DTOs below change shape.
struct ExportPayload: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let appVersion: String
    let accounts: [AccountDTO]
    let categories: [CategoryDTO]
    let transactions: [TransactionDTO]
    let budgets: [BudgetDTO]
    let savingsGoals: [SavingsGoalDTO]
}

struct SavingsGoalDTO: Codable {
    let id: UUID
    let name: String
    let targetAmount: Decimal
    let currentAmount: Decimal
    let targetDate: Date?
    let icon: String
    let colorHex: String
    let linkedAccountID: UUID?
    let createdAt: Date
}

struct BudgetDTO: Codable {
    let id: UUID
    let categoryID: UUID?
    let amount: Decimal
    let month: Date
    let rollover: Bool
    let createdAt: Date
}

struct AccountDTO: Codable {
    let id: UUID
    let name: String
    let type: String
    let balance: Decimal
    let currency: String
    let icon: String
    let colorHex: String
    let creditLimit: Decimal?
    let statementDay: Int?
    let dueDay: Int?
    let createdAt: Date
}

struct CategoryDTO: Codable {
    let id: UUID
    let name: String
    let icon: String
    let colorHex: String
    let type: String
    let sortOrder: Int
    let createdAt: Date
}

struct TransactionDTO: Codable {
    let id: UUID
    let amount: Decimal
    let type: String
    let date: Date
    let notes: String?
    let accountID: UUID?
    let toAccountID: UUID?
    let categoryID: UUID?
    let createdAt: Date
}

enum DataExportService {
    static let currentSchemaVersion = 3

    @MainActor
    static func export(from context: ModelContext) throws -> Data {
        let accounts = try context.fetch(FetchDescriptor<Account>())
        let categories = try context.fetch(FetchDescriptor<TxnCategory>())
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        let budgets = try context.fetch(FetchDescriptor<Budget>())
        let savingsGoals = try context.fetch(FetchDescriptor<SavingsGoal>())

        let payload = ExportPayload(
            schemaVersion: currentSchemaVersion,
            exportedAt: Date(),
            appVersion: appVersion,
            accounts: accounts.map(AccountDTO.init(from:)),
            categories: categories.map(CategoryDTO.init(from:)),
            transactions: transactions.map(TransactionDTO.init(from:)),
            budgets: budgets.map(BudgetDTO.init(from:)),
            savingsGoals: savingsGoals.map(SavingsGoalDTO.init(from:))
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    @MainActor
    static func writeExportFile(from context: ModelContext) throws -> URL {
        let data = try export(from: context)
        let filename = "ErvenWallet-\(timestampString()).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    private static func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: Date())
    }
}

private extension AccountDTO {
    init(from account: Account) {
        self.id = account.id
        self.name = account.name
        self.type = account.typeRaw
        self.balance = account.balance
        self.currency = account.currency
        self.icon = account.icon
        self.colorHex = account.colorHex
        self.creditLimit = account.creditLimit
        self.statementDay = account.statementDay
        self.dueDay = account.dueDay
        self.createdAt = account.createdAt
    }
}

private extension CategoryDTO {
    init(from category: TxnCategory) {
        self.id = category.id
        self.name = category.name
        self.icon = category.icon
        self.colorHex = category.colorHex
        self.type = category.typeRaw
        self.sortOrder = category.sortOrder
        self.createdAt = category.createdAt
    }
}

private extension TransactionDTO {
    init(from transaction: Transaction) {
        self.id = transaction.id
        self.amount = transaction.amount
        self.type = transaction.typeRaw
        self.date = transaction.date
        self.notes = transaction.notes
        self.accountID = transaction.account?.id
        self.toAccountID = transaction.toAccount?.id
        self.categoryID = transaction.category?.id
        self.createdAt = transaction.createdAt
    }
}

private extension BudgetDTO {
    init(from budget: Budget) {
        self.id = budget.id
        self.categoryID = budget.category?.id
        self.amount = budget.amount
        self.month = budget.month
        self.rollover = budget.rollover
        self.createdAt = budget.createdAt
    }
}

private extension SavingsGoalDTO {
    init(from goal: SavingsGoal) {
        self.id = goal.id
        self.name = goal.name
        self.targetAmount = goal.targetAmount
        self.currentAmount = goal.currentAmount
        self.targetDate = goal.targetDate
        self.icon = goal.icon
        self.colorHex = goal.colorHex
        self.linkedAccountID = goal.linkedAccount?.id
        self.createdAt = goal.createdAt
    }
}

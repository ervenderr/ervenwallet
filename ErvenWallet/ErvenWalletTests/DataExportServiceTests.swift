import Testing
import Foundation
import SwiftData
@testable import ErvenWallet

@MainActor
struct DataExportServiceTests {
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

    @Test func exportEmptyDatabaseProducesValidJSON() throws {
        let data = try DataExportService.export(from: context)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(ExportPayload.self, from: data)

        #expect(payload.schemaVersion == DataExportService.currentSchemaVersion)
        #expect(payload.accounts.isEmpty)
        #expect(payload.categories.isEmpty)
        #expect(payload.transactions.isEmpty)
        #expect(payload.budgets.isEmpty)
        #expect(payload.savingsGoals.isEmpty)
    }

    @Test func exportRoundTripsAccountsAndTransactions() throws {
        let account = Account(name: "BDO", type: .bank, balance: 5000)
        let category = TxnCategory(name: "Groceries", type: .expense)
        context.insert(account)
        context.insert(category)
        let txn = Transaction(amount: 250, type: .expense, account: account, category: category)
        context.insert(txn)
        txn.applyToBalances()

        let data = try DataExportService.export(from: context)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(ExportPayload.self, from: data)

        #expect(payload.accounts.count == 1)
        #expect(payload.accounts.first?.name == "BDO")
        #expect(payload.accounts.first?.balance == 4750)
        #expect(payload.transactions.count == 1)
        #expect(payload.transactions.first?.amount == 250)
        #expect(payload.transactions.first?.accountID == account.id)
        #expect(payload.transactions.first?.categoryID == category.id)
    }

    @Test func exportIncludesAllSchemaTypes() throws {
        let account = Account(name: "Cash", type: .cash, balance: 1000)
        let category = TxnCategory(name: "Food", type: .expense)
        context.insert(account)
        context.insert(category)

        let budget = Budget(category: category, amount: 5000, month: Date())
        context.insert(budget)

        let goal = SavingsGoal(name: "Emergency", targetAmount: 10000, currentAmount: 2500)
        context.insert(goal)

        let data = try DataExportService.export(from: context)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(ExportPayload.self, from: data)

        #expect(payload.budgets.count == 1)
        #expect(payload.budgets.first?.amount == 5000)
        #expect(payload.savingsGoals.count == 1)
        #expect(payload.savingsGoals.first?.targetAmount == 10000)
    }
}

@MainActor
struct DefaultCategoriesTests {
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

    @Test func seedsWhenEmpty() throws {
        DefaultCategories.seedIfNeeded(in: context)
        let count = try context.fetchCount(FetchDescriptor<TxnCategory>())
        #expect(count == DefaultCategories.all.count)
    }

    @Test func isIdempotent() throws {
        DefaultCategories.seedIfNeeded(in: context)
        let firstCount = try context.fetchCount(FetchDescriptor<TxnCategory>())
        DefaultCategories.seedIfNeeded(in: context)
        let secondCount = try context.fetchCount(FetchDescriptor<TxnCategory>())
        #expect(firstCount == secondCount)
    }

    @Test func includesBothExpenseAndIncome() throws {
        DefaultCategories.seedIfNeeded(in: context)
        let categories = try context.fetch(FetchDescriptor<TxnCategory>())
        let hasExpense = categories.contains { $0.type == .expense }
        let hasIncome = categories.contains { $0.type == .income }
        #expect(hasExpense)
        #expect(hasIncome)
    }
}

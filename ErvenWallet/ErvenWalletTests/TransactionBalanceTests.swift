import Testing
import Foundation
import SwiftData
@testable import ErvenWallet

@MainActor
struct TransactionBalanceTests {
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

    private func makeAccount(name: String = "Test", balance: Decimal = 1000) -> Account {
        let account = Account(name: name, type: .bank, balance: balance)
        context.insert(account)
        return account
    }

    private func makeCategory() -> TxnCategory {
        let category = TxnCategory(name: "Groceries", type: .expense)
        context.insert(category)
        return category
    }

    @Test func expenseDecreasesBalance() throws {
        let account = makeAccount(balance: 1000)
        let txn = Transaction(amount: 250, type: .expense, account: account, category: makeCategory())
        context.insert(txn)
        txn.applyToBalances()
        #expect(account.balance == 750)
    }

    @Test func incomeIncreasesBalance() throws {
        let account = makeAccount(balance: 1000)
        let txn = Transaction(amount: 500, type: .income, account: account, category: makeCategory())
        context.insert(txn)
        txn.applyToBalances()
        #expect(account.balance == 1500)
    }

    @Test func transferMovesBetweenAccounts() throws {
        let from = makeAccount(name: "BDO", balance: 5000)
        let to = makeAccount(name: "Cash", balance: 200)
        let txn = Transaction(amount: 1500, type: .transfer, account: from, toAccount: to)
        context.insert(txn)
        txn.applyToBalances()
        #expect(from.balance == 3500)
        #expect(to.balance == 1700)
    }

    @Test func revertExpenseRestoresBalance() throws {
        let account = makeAccount(balance: 1000)
        let txn = Transaction(amount: 300, type: .expense, account: account, category: makeCategory())
        context.insert(txn)
        txn.applyToBalances()
        txn.revertFromBalances()
        #expect(account.balance == 1000)
    }

    @Test func revertIncomeRestoresBalance() throws {
        let account = makeAccount(balance: 1000)
        let txn = Transaction(amount: 800, type: .income, account: account, category: makeCategory())
        context.insert(txn)
        txn.applyToBalances()
        txn.revertFromBalances()
        #expect(account.balance == 1000)
    }

    @Test func revertTransferRestoresBothBalances() throws {
        let from = makeAccount(name: "A", balance: 2000)
        let to = makeAccount(name: "B", balance: 500)
        let txn = Transaction(amount: 750, type: .transfer, account: from, toAccount: to)
        context.insert(txn)
        txn.applyToBalances()
        txn.revertFromBalances()
        #expect(from.balance == 2000)
        #expect(to.balance == 500)
    }

    @Test func multipleExpensesStack() throws {
        let account = makeAccount(balance: 10000)
        let category = makeCategory()
        for amount in [100, 250, 75, 500] {
            let txn = Transaction(amount: Decimal(amount), type: .expense, account: account, category: category)
            context.insert(txn)
            txn.applyToBalances()
        }
        #expect(account.balance == 9075)
    }

    @Test func transferToSelfPreservesNetWorth() throws {
        let from = makeAccount(name: "A", balance: 5000)
        let to = makeAccount(name: "B", balance: 3000)
        let initialNetWorth = from.balance + to.balance
        let txn = Transaction(amount: 1234, type: .transfer, account: from, toAccount: to)
        context.insert(txn)
        txn.applyToBalances()
        #expect(from.balance + to.balance == initialNetWorth)
    }

    @Test func accountTypeRoundTrips() {
        let account = Account(name: "X", type: .creditCard, balance: 0)
        #expect(account.type == .creditCard)
        #expect(account.typeRaw == AccountType.creditCard.rawValue)
    }
}

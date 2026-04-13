import SwiftUI
import SwiftData

struct WalletView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query private var transactions: [Transaction]
    @State private var showingAddSheet = false

    private var netWorth: Decimal {
        var total: Decimal = .zero
        for account in accounts {
            if account.type == .creditCard {
                total -= account.balance
            } else {
                total += account.balance
            }
        }
        return total
    }

    var body: some View {
        NavigationStack {
            Group {
                if accounts.isEmpty {
                    emptyState
                } else {
                    accountsList
                }
            }
            .navigationTitle("Wallet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddAccountSheet()
            }
        }
    }

    private func deleteAccounts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(accounts[index])
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No accounts yet", systemImage: "wallet.pass")
        } description: {
            Text("Add your first account to start tracking your money.")
        }
    }

    private var accountsList: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                NetWorthHeroCard(netWorth: netWorth, accountCount: accounts.count)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.sm)

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Accounts")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Theme.Spacing.lg)

                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(accounts) { account in
                            AccountRow(account: account, transactions: transactions)
                                .padding(Theme.Spacing.md)
                                .background(Theme.Palette.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                                .contextMenu {
                                    Button(role: .destructive) {
                                        modelContext.delete(account)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }

                Spacer(minLength: Theme.Spacing.xl)
            }
        }
        .background(Theme.Palette.surface)
    }
}

private struct NetWorthHeroCard: View {
    let netWorth: Decimal
    let accountCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Net Worth")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.85))
                Spacer()
                Image(systemName: "wallet.pass.fill")
                    .foregroundStyle(Theme.Palette.accentLight)
            }

            Text(CurrencyFormatter.format(netWorth))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "building.columns.fill")
                    .font(.caption2)
                Text("\(accountCount) \(accountCount == 1 ? "account" : "accounts")")
                    .font(.caption)
            }
            .foregroundStyle(Color.white.opacity(0.75))
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Gradients.hero)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        .themeShadow(Theme.Shadow.hero)
    }
}

private struct AccountRow: View {
    let account: Account
    let transactions: [Transaction]

    var body: some View {
        HStack {
            Image(systemName: account.icon)
                .frame(width: 32, height: 32)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                Text(account.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if account.type == .creditCard {
                    creditCardDetails
                }
            }
            Spacer()
            Text(CurrencyFormatter.format(account.balance, currency: account.currency))
                .font(.body.monospacedDigit())
        }
    }

    @ViewBuilder
    private var creditCardDetails: some View {
        if let limit = account.creditLimit {
            let available = CreditCardMath.availableCredit(creditLimit: limit, currentBalance: account.balance)
            HStack(spacing: 4) {
                Image(systemName: "creditcard")
                    .font(.caption2)
                Text("\(CurrencyFormatter.format(available)) available")
                    .font(.caption2)
            }
            .foregroundStyle(available > 0 ? Color.secondary : Color.red)
        }

        if let statementDay = account.statementDay {
            let spent = CreditCardMath.thisStatementSpend(
                transactions: transactions,
                accountID: account.id,
                statementDay: statementDay
            )
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .font(.caption2)
                Text("This statement: \(CurrencyFormatter.format(spent))")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }

        if let dueDay = account.dueDay,
           let days = CreditCardMath.daysUntilDue(asOf: Date(), dueDay: dueDay) {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption2)
                Text(daysUntilDueLabel(days))
                    .font(.caption2)
            }
            .foregroundStyle(days <= 3 ? Color.red : Color.secondary)
        }
    }

    private func daysUntilDueLabel(_ days: Int) -> String {
        switch days {
        case 0: return "Due today"
        case 1: return "Due tomorrow"
        default: return "Due in \(days) days"
        }
    }
}

#Preview {
    WalletView()
        .modelContainer(for: Account.self, inMemory: true)
}

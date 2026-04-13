import SwiftUI
import SwiftData

struct WalletView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query private var transactions: [Transaction]
    @State private var showingAddSheet = false
    @State private var editingAccount: Account?

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
                AddAccountSheet().themeSheet()
            }
            .sheet(item: $editingAccount) { account in
                AddAccountSheet(editing: account).themeSheet()
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
        } actions: {
            Button {
                showingAddSheet = true
                Haptics.impact(.light)
            } label: {
                Label("Add Account", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Palette.primary)
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
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingAccount = account
                                    Haptics.impact(.light)
                                }
                                .contextMenu {
                                    Button {
                                        editingAccount = account
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        modelContext.delete(account)
                                        Haptics.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }

                monthSnapshot
                    .padding(.horizontal, Theme.Spacing.lg)

                Spacer(minLength: Theme.Spacing.xl)
            }
        }
        .background(Theme.Palette.surface)
    }

    private var monthSnapshot: some View {
        let (spent, income, topCategory) = currentMonthStats()
        return VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("This Month")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: Theme.Spacing.md) {
                MiniStatCard(
                    label: "Spent",
                    value: CurrencyFormatter.format(spent),
                    icon: "arrow.down.right",
                    tint: Theme.Palette.expense
                )
                MiniStatCard(
                    label: "Income",
                    value: CurrencyFormatter.format(income),
                    icon: "arrow.up.right",
                    tint: Theme.Palette.income
                )
            }

            if let top = topCategory {
                HStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(CategoryColor.color(for: top.name).opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: top.icon)
                            .foregroundStyle(CategoryColor.color(for: top.name))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Top category")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(top.name)
                            .font(.body.weight(.medium))
                    }
                    Spacer()
                    Text(CurrencyFormatter.format(top.amount))
                        .font(.body.monospacedDigit().weight(.semibold))
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Palette.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
            }
        }
    }

    private func currentMonthStats() -> (spent: Decimal, income: Decimal, top: (name: String, icon: String, amount: Decimal)?) {
        let calendar = Calendar.current
        let now = Date()
        var spent: Decimal = 0
        var income: Decimal = 0
        var categoryTotals: [String: (icon: String, amount: Decimal)] = [:]

        for txn in transactions {
            guard calendar.isDate(txn.date, equalTo: now, toGranularity: .month) else { continue }
            switch txn.type {
            case .expense:
                spent += txn.amount
                let name = txn.category?.name ?? "Uncategorized"
                let icon = txn.category?.icon ?? "tag"
                let existing = categoryTotals[name]?.amount ?? 0
                categoryTotals[name] = (icon, existing + txn.amount)
            case .income:
                income += txn.amount
            case .transfer:
                break
            }
        }

        let top = categoryTotals
            .max { $0.value.amount < $1.value.amount }
            .map { ($0.key, $0.value.icon, $0.value.amount) }

        return (spent, income, top)
    }
}

private struct MiniStatCard: View {
    let label: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(tint)

            Text(value)
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(Theme.Palette.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
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
                .contentTransition(.numericText())
                .animation(.snappy, value: netWorth)

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

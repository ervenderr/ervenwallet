import SwiftUI
import SwiftData

struct AccountDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let account: Account

    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @State private var editingTransaction: Transaction?
    @State private var editingAccount: Account?

    private var accountTransactions: [Transaction] {
        let id = account.id
        return allTransactions.filter { txn in
            txn.account?.id == id || txn.toAccount?.id == id
        }
    }

    private var thisMonthSpend: Decimal {
        let calendar = Calendar.current
        let now = Date()
        var total: Decimal = 0
        for txn in accountTransactions {
            guard calendar.isDate(txn.date, equalTo: now, toGranularity: .month),
                  txn.account?.id == account.id else { continue }
            if txn.type == .expense || txn.type == .transfer {
                total += txn.amount
            }
        }
        return total
    }

    private var thisMonthIncome: Decimal {
        let calendar = Calendar.current
        let now = Date()
        var total: Decimal = 0
        for txn in accountTransactions where txn.type == .income {
            guard calendar.isDate(txn.date, equalTo: now, toGranularity: .month),
                  txn.account?.id == account.id else { continue }
            total += txn.amount
        }
        return total
    }

    private var groupedByDay: [(key: Date, value: [Transaction])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: accountTransactions) { txn in
            calendar.startOfDay(for: txn.date)
        }
        return groups.sorted { $0.key > $1.key }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerCard
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.sm)

                monthStats
                    .padding(.horizontal, Theme.Spacing.lg)

                if accountTransactions.isEmpty {
                    ContentUnavailableView(
                        "No transactions",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Transactions involving this account will appear here.")
                    )
                    .padding(.top, Theme.Spacing.xl)
                } else {
                    transactionList
                }

                Spacer(minLength: Theme.Spacing.xl)
            }
        }
        .background(Theme.Palette.surface)
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingAccount = account
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(item: $editingAccount) { acc in
            AddAccountSheet(editing: acc).themeSheet()
        }
        .sheet(item: $editingTransaction) { txn in
            AddTransactionSheet(editing: txn)
                .presentationDragIndicator(.visible)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: account.icon)
                    .font(.title2)
                    .foregroundStyle(Theme.Palette.accentLight)
                Text(account.type.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.85))
                Spacer()
            }

            Text(CurrencyFormatter.format(account.balance, currency: account.currency))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.snappy, value: account.balance)

            if account.type == .creditCard,
               let limit = account.creditLimit {
                let available = CreditCardMath.availableCredit(
                    creditLimit: limit,
                    currentBalance: account.balance
                )
                Text("\(CurrencyFormatter.format(available)) available")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Palette.accentLight)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Gradients.hero)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        .themeShadow(Theme.Shadow.hero)
    }

    private var monthStats: some View {
        HStack(spacing: Theme.Spacing.md) {
            MiniStat(
                label: "Spent (mo)",
                value: CurrencyFormatter.format(thisMonthSpend),
                icon: "arrow.down.right",
                tint: Theme.Palette.expense
            )
            MiniStat(
                label: "Income (mo)",
                value: CurrencyFormatter.format(thisMonthIncome),
                icon: "arrow.up.right",
                tint: Theme.Palette.income
            )
        }
    }

    private var transactionList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            ForEach(groupedByDay, id: \.key) { day, items in
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(day, format: .dateTime.weekday(.wide).month().day())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Theme.Spacing.lg)

                    VStack(spacing: 1) {
                        ForEach(items) { txn in
                            DetailTransactionRow(transaction: txn, accountID: account.id)
                                .padding(Theme.Spacing.md)
                                .background(Theme.Palette.surfaceElevated)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingTransaction = txn
                                    Haptics.impact(.light)
                                }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                    .padding(.horizontal, Theme.Spacing.lg)
                }
            }
        }
    }
}

private struct MiniStat: View {
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

private struct DetailTransactionRow: View {
    let transaction: Transaction
    let accountID: UUID

    private var amountLabel: String {
        let prefix: String
        switch transaction.type {
        case .expense:
            prefix = "-"
        case .income:
            prefix = "+"
        case .transfer:
            // Incoming transfer to this account is positive, outgoing is negative.
            prefix = transaction.toAccount?.id == accountID ? "+" : "-"
        }
        return prefix + CurrencyFormatter.format(transaction.amount)
    }

    private var amountColor: Color {
        switch transaction.type {
        case .expense: return Theme.Palette.expense
        case .income: return Theme.Palette.income
        case .transfer:
            return transaction.toAccount?.id == accountID ? Theme.Palette.income : Theme.Palette.expense
        }
    }

    private var iconName: String {
        if transaction.type == .transfer { return "arrow.left.arrow.right" }
        return transaction.category?.icon ?? "tag"
    }

    private var tint: Color {
        if transaction.type == .transfer { return Theme.Palette.primary }
        if let name = transaction.category?.name {
            return CategoryColor.color(for: name)
        }
        return amountColor
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category?.name ?? (transaction.type == .transfer ? "Transfer" : "Uncategorized"))
                    .font(.body)
                if let notes = transaction.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(amountLabel)
                .font(.body.monospacedDigit().weight(.semibold))
                .foregroundStyle(amountColor)
        }
    }
}

import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if transactions.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Transactions")
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
                AddTransactionSheet()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No transactions yet", systemImage: "list.bullet.rectangle")
        } description: {
            Text("Tap + to log your first expense, income, or transfer.")
        }
    }

    private var list: some View {
        List {
            ForEach(groupedByDay, id: \.key) { day, items in
                Section(header: Text(day, format: .dateTime.weekday(.wide).month().day())) {
                    ForEach(items) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                    .onDelete { offsets in
                        delete(items: items, at: offsets)
                    }
                }
            }
        }
    }

    private var groupedByDay: [(key: Date, value: [Transaction])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.date)
        }
        return groups.sorted { $0.key > $1.key }
    }

    private func delete(items: [Transaction], at offsets: IndexSet) {
        for index in offsets {
            let transaction = items[index]
            transaction.revertFromBalances()
            modelContext.delete(transaction)
        }
    }
}

private struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: iconName)
                    .foregroundStyle(.tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(primaryLabel)
                    .font(.body)
                Text(secondaryLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(amountLabel)
                .font(.body.monospacedDigit())
                .foregroundStyle(amountColor)
        }
        .padding(.vertical, 2)
    }

    private var iconName: String {
        if transaction.type == .transfer { return "arrow.left.arrow.right" }
        return transaction.category?.icon ?? "tag"
    }

    private var primaryLabel: String {
        switch transaction.type {
        case .transfer:
            let from = transaction.account?.name ?? "?"
            let to = transaction.toAccount?.name ?? "?"
            return "\(from) → \(to)"
        case .expense, .income:
            return transaction.category?.name ?? "Uncategorized"
        }
    }

    private var secondaryLabel: String {
        switch transaction.type {
        case .transfer:
            return "Transfer"
        case .expense, .income:
            return transaction.account?.name ?? "—"
        }
    }

    private var amountLabel: String {
        let prefix: String
        switch transaction.type {
        case .expense: prefix = "-"
        case .income: prefix = "+"
        case .transfer: prefix = ""
        }
        return prefix + CurrencyFormatter.format(transaction.amount)
    }

    private var amountColor: Color {
        switch transaction.type {
        case .expense: return .red
        case .income: return .green
        case .transfer: return .primary
        }
    }
}

#Preview {
    TransactionListView()
        .modelContainer(for: [Account.self, TxnCategory.self, Transaction.self], inMemory: true)
}

import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @State private var showingAddSheet = false
    @State private var editingTransaction: Transaction?
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable, Identifiable {
        case all, expense, income, transfer
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all: return "All"
            case .expense: return "Expense"
            case .income: return "Income"
            case .transfer: return "Transfer"
            }
        }
    }

    private var filteredTransactions: [Transaction] {
        switch filter {
        case .all: return transactions
        case .expense: return transactions.filter { $0.type == .expense }
        case .income: return transactions.filter { $0.type == .income }
        case .transfer: return transactions.filter { $0.type == .transfer }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if transactions.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        Picker("Filter", selection: $filter) {
                            ForEach(Filter.allCases) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.sm)
                        .padding(.bottom, Theme.Spacing.xs)

                        if filteredTransactions.isEmpty {
                            ContentUnavailableView(
                                "No \(filter.label.lowercased()) transactions",
                                systemImage: "line.3.horizontal.decrease.circle"
                            )
                        } else {
                            list
                        }
                    }
                }
            }
            .navigationTitle("Transactions")
            .overlay(alignment: .bottomTrailing) {
                if !transactions.isEmpty {
                    FloatingAddButton {
                        showingAddSheet = true
                        Haptics.impact(.light)
                    }
                    .padding(.trailing, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.lg)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTransactionSheet()
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingTransaction) { transaction in
                AddTransactionSheet(editing: transaction)
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No transactions yet", systemImage: "list.bullet.rectangle")
        } description: {
            Text("Tap to log your first expense, income, or transfer.")
        } actions: {
            Button {
                showingAddSheet = true
                Haptics.impact(.light)
            } label: {
                Label("Log Transaction", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Palette.primary)
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.lg, pinnedViews: []) {
                ForEach(groupedByDay, id: \.key) { day, items in
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text(day, format: .dateTime.weekday(.wide).month().day())
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, Theme.Spacing.lg)

                        VStack(spacing: 1) {
                            ForEach(items) { transaction in
                                TransactionRow(transaction: transaction)
                                    .padding(Theme.Spacing.md)
                                    .background(Theme.Palette.surfaceElevated)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingTransaction = transaction
                                        Haptics.impact(.light)
                                    }
                                    .contextMenu {
                                        Button {
                                            editingTransaction = transaction
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        Button(role: .destructive) {
                                            transaction.revertFromBalances()
                                            modelContext.delete(transaction)
                                            Haptics.impact(.medium)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                        .padding(.horizontal, Theme.Spacing.lg)
                    }
                }
                Spacer(minLength: Theme.Spacing.xl)
            }
            .padding(.top, Theme.Spacing.sm)
        }
        .background(Theme.Palette.surface)
    }

    private var groupedByDay: [(key: Date, value: [Transaction])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredTransactions) { transaction in
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
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 40, height: 40)
                Image(systemName: iconName)
                    .foregroundStyle(iconForeground)
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
                .font(.body.monospacedDigit().weight(.semibold))
                .foregroundStyle(amountColor)
        }
    }

    private var iconTint: Color {
        if transaction.type == .transfer {
            return Theme.Palette.primary
        }
        if let name = transaction.category?.name {
            return CategoryColor.color(for: name)
        }
        return transaction.type == .expense ? Theme.Palette.expense : Theme.Palette.income
    }

    private var iconBackground: Color { iconTint.opacity(0.15) }
    private var iconForeground: Color { iconTint }

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
        case .expense: return Theme.Palette.expense
        case .income: return Theme.Palette.income
        case .transfer: return .primary
        }
    }
}

#Preview {
    TransactionListView()
        .modelContainer(for: [Account.self, TxnCategory.self, Transaction.self], inMemory: true)
}

import SwiftUI
import SwiftData

struct BudgetOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Budget.createdAt) private var budgets: [Budget]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var showingAddSheet = false

    private var currentMonth: Date {
        Budget.normalize(month: Date())
    }

    private var currentMonthBudgets: [Budget] {
        budgets.filter { $0.month == currentMonth }
    }

    private var totalBudgeted: Decimal {
        currentMonthBudgets.reduce(.zero) { $0 + $1.amount }
    }

    private var totalSpent: Decimal {
        currentMonthBudgets.reduce(.zero) { $0 + spent(for: $1) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if currentMonthBudgets.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Budget")
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
                AddBudgetSheet(month: currentMonth)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No budgets this month", systemImage: "chart.pie")
        } description: {
            Text("Set monthly limits per category to track your spending.")
        }
    }

    private var list: some View {
        List {
            Section {
                summaryHeader
            }

            Section("Categories") {
                ForEach(currentMonthBudgets) { budget in
                    BudgetRow(budget: budget, spent: spent(for: budget))
                }
                .onDelete(perform: deleteBudgets)
            }
        }
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(currentMonth, format: .dateTime.month(.wide).year())
                .font(.title3.weight(.semibold))
            HStack {
                VStack(alignment: .leading) {
                    Text("Spent").font(.caption).foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(totalSpent))
                        .font(.headline.monospacedDigit())
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Budgeted").font(.caption).foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(totalBudgeted))
                        .font(.headline.monospacedDigit())
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func spent(for budget: Budget) -> Decimal {
        guard let categoryID = budget.category?.id else { return .zero }
        let calendar = Calendar.current
        return transactions
            .filter { transaction in
                transaction.type == .expense
                    && transaction.category?.id == categoryID
                    && calendar.isDate(transaction.date, equalTo: budget.month, toGranularity: .month)
            }
            .reduce(.zero) { $0 + $1.amount }
    }

    private func deleteBudgets(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(currentMonthBudgets[index])
        }
    }
}

private struct BudgetRow: View {
    let budget: Budget
    let spent: Decimal

    private var progress: Double {
        guard budget.amount > 0 else { return 0 }
        let value = (spent as NSDecimalNumber).doubleValue / (budget.amount as NSDecimalNumber).doubleValue
        return min(max(value, 0), 1.5)
    }

    private var progressColor: Color {
        switch progress {
        case ..<0.8: return .green
        case ..<1.0: return .orange
        default: return .red
        }
    }

    private var remaining: Decimal {
        budget.amount - spent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(budget.category?.name ?? "Unknown", systemImage: budget.category?.icon ?? "tag")
                    .labelStyle(.titleAndIcon)
                Spacer()
                Text("\(CurrencyFormatter.format(spent)) / \(CurrencyFormatter.format(budget.amount))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: min(progress, 1.0))
                .tint(progressColor)

            HStack {
                Text(remaining >= 0
                    ? "\(CurrencyFormatter.format(remaining)) left"
                    : "Over by \(CurrencyFormatter.format(-remaining))")
                    .font(.caption2)
                    .foregroundStyle(remaining >= 0 ? Color.secondary : Color.red)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BudgetOverviewView()
        .modelContainer(for: [Account.self, Category.self, Transaction.self, Budget.self], inMemory: true)
}

import SwiftUI
import SwiftData

struct BudgetOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Budget.createdAt) private var budgets: [Budget]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var showingAddSheet = false
    @State private var editingBudget: Budget?

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
                AddBudgetSheet(month: currentMonth).themeSheet()
            }
            .sheet(item: $editingBudget) { budget in
                AddBudgetSheet(month: currentMonth, editing: budget).themeSheet()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No budgets this month", systemImage: "chart.pie")
        } description: {
            Text("Set monthly limits per category to track your spending.")
        } actions: {
            Button {
                showingAddSheet = true
                Haptics.impact(.light)
            } label: {
                Label("Create Budget", systemImage: "plus")
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
            VStack(spacing: Theme.Spacing.lg) {
                summaryHeader
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.sm)

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Categories")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Theme.Spacing.lg)

                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(currentMonthBudgets) { budget in
                            BudgetRow(budget: budget, spent: spent(for: budget))
                                .padding(Theme.Spacing.md)
                                .background(Theme.Palette.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingBudget = budget
                                    Haptics.impact(.light)
                                }
                                .contextMenu {
                                    Button {
                                        editingBudget = budget
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        modelContext.delete(budget)
                                        Haptics.impact(.medium)
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

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(currentMonth, format: .dateTime.month(.wide).year())
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.85))

            Text(CurrencyFormatter.format(totalSpent))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.snappy, value: totalSpent)

            HStack {
                Text("of \(CurrencyFormatter.format(totalBudgeted))")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.75))
                Spacer()
                let remaining = totalBudgeted - totalSpent
                Text(remaining >= 0 ? "\(CurrencyFormatter.format(remaining)) left" : "Over by \(CurrencyFormatter.format(-remaining))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(remaining >= 0 ? Theme.Palette.accentLight : Color.white)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Gradients.hero)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        .themeShadow(Theme.Shadow.hero)
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
        case ..<0.8: return Theme.Palette.income
        case ..<1.0: return Theme.Palette.accent
        default: return Theme.Palette.expense
        }
    }

    private var remaining: Decimal {
        budget.amount - spent
    }

    private var categoryTint: Color {
        CategoryColor.color(for: budget.category?.name ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(categoryTint.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: budget.category?.icon ?? "tag")
                        .foregroundStyle(categoryTint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(budget.category?.name ?? "Unknown")
                        .font(.body.weight(.medium))
                    Text("\(CurrencyFormatter.format(spent)) of \(CurrencyFormatter.format(budget.amount))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(progressColor)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [progressColor.opacity(0.7), progressColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * min(progress, 1.0))
                        .animation(.snappy, value: progress)
                }
            }
            .frame(height: 8)

            Text(remaining >= 0
                ? "\(CurrencyFormatter.format(remaining)) left"
                : "Over by \(CurrencyFormatter.format(-remaining))")
                .font(.caption2)
                .foregroundStyle(remaining >= 0 ? Color.secondary : Theme.Palette.expense)
        }
    }
}

#Preview {
    BudgetOverviewView()
        .modelContainer(for: [Account.self, TxnCategory.self, Transaction.self, Budget.self], inMemory: true)
}

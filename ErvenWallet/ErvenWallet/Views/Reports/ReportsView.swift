import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var accounts: [Account]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                monthSummarySection
                categoryBreakdownSection
                spendingTrendSection
                netWorthSection
            }
            .padding()
        }
        .navigationTitle("Reports")
    }

    // MARK: - Month summary (income vs expense)

    private var monthSummarySection: some View {
        let (income, expense) = currentMonthTotals()
        let data: [MonthBar] = [
            MonthBar(label: "Income", amount: income, color: .green),
            MonthBar(label: "Expense", amount: expense, color: .red)
        ]
        return VStack(alignment: .leading, spacing: 8) {
            Text("This Month")
                .font(.headline)
            Chart(data) { bar in
                BarMark(
                    x: .value("Kind", bar.label),
                    y: .value("Amount", NSDecimalNumber(decimal: bar.amount).doubleValue)
                )
                .foregroundStyle(bar.color)
                .annotation(position: .top) {
                    Text(CurrencyFormatter.format(bar.amount))
                        .font(.caption2)
                }
            }
            .frame(height: 180)
            let net = income - expense
            Text("Net: \(CurrencyFormatter.format(net))")
                .font(.subheadline)
                .foregroundStyle(net >= 0 ? Color.green : Color.red)
        }
    }

    private func currentMonthTotals() -> (income: Decimal, expense: Decimal) {
        let calendar = Calendar.current
        let now = Date()
        var income: Decimal = 0
        var expense: Decimal = 0
        for txn in transactions {
            guard calendar.isDate(txn.date, equalTo: now, toGranularity: .month) else { continue }
            switch txn.type {
            case .income: income += txn.amount
            case .expense: expense += txn.amount
            case .transfer: break
            }
        }
        return (income, expense)
    }

    // MARK: - Category breakdown (this month expenses)

    private var categoryBreakdownSection: some View {
        let slices = currentMonthCategoryBreakdown()
        return VStack(alignment: .leading, spacing: 8) {
            Text("Spending by Category")
                .font(.headline)
            if slices.isEmpty {
                Text("No expenses this month.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Amount", NSDecimalNumber(decimal: slice.amount).doubleValue),
                        innerRadius: .ratio(0.55),
                        angularInset: 1
                    )
                    .foregroundStyle(by: .value("Category", slice.name))
                }
                .frame(height: 220)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(slices) { slice in
                        HStack {
                            Text(slice.name)
                            Spacer()
                            Text(CurrencyFormatter.format(slice.amount))
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }

    private func currentMonthCategoryBreakdown() -> [CategorySlice] {
        let calendar = Calendar.current
        let now = Date()
        var totals: [String: Decimal] = [:]
        for txn in transactions {
            guard txn.type == .expense,
                  calendar.isDate(txn.date, equalTo: now, toGranularity: .month) else { continue }
            let name = txn.category?.name ?? "Uncategorized"
            totals[name, default: 0] += txn.amount
        }
        return totals
            .map { CategorySlice(name: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: - Spending trend (last 30 days)

    private var spendingTrendSection: some View {
        let points = last30DaysSpending()
        return VStack(alignment: .leading, spacing: 8) {
            Text("Spending — Last 30 Days")
                .font(.headline)
            Chart(points) { point in
                LineMark(
                    x: .value("Day", point.date),
                    y: .value("Amount", NSDecimalNumber(decimal: point.amount).doubleValue)
                )
                .interpolationMethod(.monotone)
                AreaMark(
                    x: .value("Day", point.date),
                    y: .value("Amount", NSDecimalNumber(decimal: point.amount).doubleValue)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(.red.opacity(0.2))
            }
            .frame(height: 180)
        }
    }

    private func last30DaysSpending() -> [DayPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -29, to: today) else { return [] }

        var buckets: [Date: Decimal] = [:]
        for offset in 0..<30 {
            if let day = calendar.date(byAdding: .day, value: offset, to: start) {
                buckets[day] = 0
            }
        }
        for txn in transactions where txn.type == .expense {
            let day = calendar.startOfDay(for: txn.date)
            guard day >= start, day <= today else { continue }
            buckets[day, default: 0] += txn.amount
        }
        return buckets
            .map { DayPoint(date: $0.key, amount: $0.value) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Net worth (cumulative from transactions)

    private var netWorthSection: some View {
        let points = netWorthOverTime()
        return VStack(alignment: .leading, spacing: 8) {
            Text("Net Worth Trend")
                .font(.headline)
            if points.count < 2 {
                Text("Not enough history yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Day", point.date),
                        y: .value("Net Worth", NSDecimalNumber(decimal: point.amount).doubleValue)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(.blue)
                }
                .frame(height: 180)
            }
        }
    }

    private func netWorthOverTime() -> [DayPoint] {
        let currentNetWorth: Decimal = {
            var total: Decimal = 0
            for account in accounts {
                if account.type == .creditCard {
                    total -= account.balance
                } else {
                    total += account.balance
                }
            }
            return total
        }()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -29, to: today) else { return [] }

        // Walk backward from today's net worth, reversing each day's transactions.
        var dailyDelta: [Date: Decimal] = [:]
        for txn in transactions {
            let day = calendar.startOfDay(for: txn.date)
            guard day >= start, day <= today else { continue }
            let delta: Decimal
            switch txn.type {
            case .income: delta = txn.amount
            case .expense: delta = -txn.amount
            case .transfer: delta = 0
            }
            dailyDelta[day, default: 0] += delta
        }

        var points: [DayPoint] = []
        var running = currentNetWorth
        var cursor = today
        while cursor >= start {
            points.append(DayPoint(date: cursor, amount: running))
            running -= (dailyDelta[cursor] ?? 0)
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return points.sorted { $0.date < $1.date }
    }
}

private struct MonthBar: Identifiable {
    let id = UUID()
    let label: String
    let amount: Decimal
    let color: Color
}

private struct CategorySlice: Identifiable {
    let id = UUID()
    let name: String
    let amount: Decimal
}

private struct DayPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Decimal
}

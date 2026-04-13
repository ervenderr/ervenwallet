import SwiftUI
import SwiftData

struct GoalsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavingsGoal.createdAt) private var goals: [SavingsGoal]

    @State private var showingAddSheet = false
    @State private var contributingTo: SavingsGoal?

    var body: some View {
        NavigationStack {
            Group {
                if goals.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Goals")
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
                AddGoalSheet()
            }
            .sheet(item: $contributingTo) { goal in
                LogContributionSheet(goal: goal)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No goals yet", systemImage: "target")
        } description: {
            Text("Set a savings target — emergency fund, new laptop, travel.")
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                ForEach(goals) { goal in
                    GoalRow(goal: goal)
                        .padding(Theme.Spacing.lg)
                        .background(Theme.Palette.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                        .onTapGesture {
                            contributingTo = goal
                            Haptics.impact(.light)
                        }
                        .contextMenu {
                            Button {
                                contributingTo = goal
                            } label: {
                                Label("Contribute", systemImage: "plus.circle")
                            }
                            Button(role: .destructive) {
                                modelContext.delete(goal)
                                Haptics.impact(.medium)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                Spacer(minLength: Theme.Spacing.xl)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.sm)
        }
        .background(Theme.Palette.surface)
    }

    private func deleteGoals(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(goals[index])
        }
    }
}

private struct GoalRow: View {
    let goal: SavingsGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(goal.name, systemImage: goal.icon)
                    .font(.headline)
                Spacer()
                if goal.isComplete {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }

            ProgressView(value: goal.progress)
                .tint(goal.isComplete ? Theme.Palette.income : Theme.Palette.primary)

            HStack {
                Text("\(CurrencyFormatter.format(goal.currentAmount)) / \(CurrencyFormatter.format(goal.targetAmount))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(goal.progress * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if let daily = goal.dailyRequired, let targetDate = goal.targetDate {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text("Save \(CurrencyFormatter.format(daily))/day until \(targetDate, format: .dateTime.month().day().year())")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct LogContributionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let goal: SavingsGoal
    @State private var amountText: String = ""

    private var parsedAmount: Decimal {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "")) ?? .zero
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(goal.name) {
                    HStack {
                        Text("Current")
                        Spacer()
                        Text(CurrencyFormatter.format(goal.currentAmount))
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Target")
                        Spacer()
                        Text(CurrencyFormatter.format(goal.targetAmount))
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Add Contribution") {
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.title2.monospacedDigit())
                }
            }
            .navigationTitle("Log Contribution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        goal.currentAmount += parsedAmount
                        Haptics.notify(.success)
                        dismiss()
                    }
                    .disabled(parsedAmount <= 0)
                }
            }
        }
    }
}

#Preview {
    GoalsListView()
        .modelContainer(for: [Account.self, SavingsGoal.self], inMemory: true)
}

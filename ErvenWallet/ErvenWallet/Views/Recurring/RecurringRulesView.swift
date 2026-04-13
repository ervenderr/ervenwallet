import SwiftUI
import SwiftData

struct RecurringRulesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecurringRule.createdAt) private var rules: [RecurringRule]

    @State private var editingRule: RecurringRule?

    var body: some View {
        Group {
            if rules.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Recurring")
        .sheet(item: $editingRule) { rule in
            EditRecurringRuleSheet(rule: rule).themeSheet()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No recurring entries", systemImage: "repeat")
        } description: {
            Text("Toggle Recurring on a transaction to set up automatic entries.")
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(rules) { rule in
                    RecurringRuleRow(rule: rule)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Palette.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingRule = rule
                            Haptics.impact(.light)
                        }
                        .contextMenu {
                            Button {
                                editingRule = rule
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                modelContext.delete(rule)
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
}

private struct RecurringRuleRow: View {
    let rule: RecurringRule

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(rule.displayLabel, systemImage: iconName)
                    .font(.body)
                Spacer()
                Text(amountLabel)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(amountColor)
            }

            HStack(spacing: 6) {
                Image(systemName: "repeat")
                    .font(.caption2)
                Text(rule.frequency.rawValue.capitalized)
                    .font(.caption)
                Text("·")
                    .font(.caption)
                Text("Next \(rule.nextOccurrence, format: .dateTime.month().day().year())")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            if let endDate = rule.endDate {
                Text("Ends \(endDate, format: .dateTime.month().day().year())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        if rule.type == .transfer { return "arrow.left.arrow.right" }
        return rule.category?.icon ?? "tag"
    }

    private var amountLabel: String {
        let prefix: String
        switch rule.type {
        case .expense: prefix = "-"
        case .income: prefix = "+"
        case .transfer: prefix = ""
        }
        return prefix + CurrencyFormatter.format(rule.amount)
    }

    private var amountColor: Color {
        switch rule.type {
        case .expense: return Theme.Palette.expense
        case .income: return Theme.Palette.income
        case .transfer: return .primary
        }
    }
}

#Preview {
    NavigationStack {
        RecurringRulesView()
            .modelContainer(for: [Account.self, TxnCategory.self, Transaction.self, RecurringRule.self], inMemory: true)
    }
}

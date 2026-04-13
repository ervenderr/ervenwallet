import SwiftUI
import SwiftData

struct RecurringRulesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecurringRule.createdAt) private var rules: [RecurringRule]

    var body: some View {
        Group {
            if rules.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Recurring")
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No recurring entries", systemImage: "repeat")
        } description: {
            Text("Toggle Recurring on a transaction to set up automatic entries.")
        }
    }

    private var list: some View {
        List {
            ForEach(rules) { rule in
                RecurringRuleRow(rule: rule)
            }
            .onDelete(perform: deleteRules)
        }
    }

    private func deleteRules(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(rules[index])
        }
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
        case .expense: return .red
        case .income: return .green
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

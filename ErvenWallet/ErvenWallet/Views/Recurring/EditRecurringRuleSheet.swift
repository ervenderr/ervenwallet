import SwiftUI
import SwiftData

/// Edit existing recurring rule fields. Changing the rule does not
/// retroactively alter transactions already materialized by the generator
/// — only future occurrences will reflect the new values.
struct EditRecurringRuleSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query(sort: \TxnCategory.sortOrder) private var categories: [TxnCategory]

    let rule: RecurringRule

    @State private var amountText: String
    @State private var frequency: Frequency
    @State private var notes: String
    @State private var selectedAccountID: UUID?
    @State private var selectedToAccountID: UUID?
    @State private var selectedCategoryID: UUID?
    @State private var hasEndDate: Bool
    @State private var endDate: Date

    init(rule: RecurringRule) {
        self.rule = rule
        _amountText = State(initialValue: "\(rule.amount)")
        _frequency = State(initialValue: rule.frequency)
        _notes = State(initialValue: rule.notes ?? "")
        _selectedAccountID = State(initialValue: rule.account?.id)
        _selectedToAccountID = State(initialValue: rule.toAccount?.id)
        _selectedCategoryID = State(initialValue: rule.category?.id)
        _hasEndDate = State(initialValue: rule.endDate != nil)
        _endDate = State(initialValue: rule.endDate ?? Date().addingTimeInterval(60 * 60 * 24 * 365))
    }

    private var parsedAmount: Decimal {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "")) ?? .zero
    }

    private var filteredCategories: [TxnCategory] {
        let target: CategoryType = rule.type == .income ? .income : .expense
        return categories.filter { $0.type == target }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.title2.monospacedDigit())
                }

                Section("Frequency") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Frequency.allCases) { freq in
                            Text(freq.rawValue.capitalized).tag(freq)
                        }
                    }
                }

                if rule.type != .transfer {
                    Section("Category") {
                        Picker("Category", selection: $selectedCategoryID) {
                            Text("Select…").tag(UUID?.none)
                            ForEach(filteredCategories) { category in
                                Label(category.name, systemImage: category.icon)
                                    .tag(Optional(category.id))
                            }
                        }
                    }
                }

                Section(rule.type == .transfer ? "From Account" : "Account") {
                    Picker("Account", selection: $selectedAccountID) {
                        Text("Select…").tag(UUID?.none)
                        ForEach(accounts) { account in
                            Label(account.name, systemImage: account.icon)
                                .tag(Optional(account.id))
                        }
                    }
                }

                if rule.type == .transfer {
                    Section("To Account") {
                        Picker("To Account", selection: $selectedToAccountID) {
                            Text("Select…").tag(UUID?.none)
                            ForEach(accounts.filter { $0.id != selectedAccountID }) { account in
                                Label(account.name, systemImage: account.icon)
                                    .tag(Optional(account.id))
                            }
                        }
                    }
                }

                Section {
                    Toggle("Set end date", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("Ends on", selection: $endDate, displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .navigationTitle("Edit Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(parsedAmount <= 0)
                }
            }
        }
    }

    private func save() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        rule.amount = parsedAmount
        rule.frequencyRaw = frequency.rawValue
        rule.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        rule.endDate = hasEndDate ? endDate : nil
        if let id = selectedAccountID {
            rule.account = accounts.first { $0.id == id }
        }
        if rule.type == .transfer, let id = selectedToAccountID {
            rule.toAccount = accounts.first { $0.id == id }
        }
        if rule.type != .transfer, let id = selectedCategoryID {
            rule.category = categories.first { $0.id == id }
        }
        Haptics.notify(.success)
        dismiss()
    }
}

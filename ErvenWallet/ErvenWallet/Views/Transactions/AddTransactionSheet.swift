import SwiftUI
import SwiftData

struct AddTransactionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query(sort: \TxnCategory.sortOrder) private var categories: [TxnCategory]

    let editing: Transaction?

    @State private var type: TransactionType
    @State private var amountText: String
    @State private var date: Date
    @State private var notes: String
    @State private var selectedCategoryID: UUID?
    @State private var selectedAccountID: UUID?
    @State private var selectedToAccountID: UUID?
    @State private var isRecurring: Bool = false
    @State private var frequency: Frequency = .monthly
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date().addingTimeInterval(60 * 60 * 24 * 365)

    init(editing: Transaction? = nil) {
        self.editing = editing
        _type = State(initialValue: editing?.type ?? .expense)
        _amountText = State(initialValue: editing.map { "\($0.amount)" } ?? "")
        _date = State(initialValue: editing?.date ?? Date())
        _notes = State(initialValue: editing?.notes ?? "")
        _selectedCategoryID = State(initialValue: editing?.category?.id)
        _selectedAccountID = State(initialValue: editing?.account?.id)
        _selectedToAccountID = State(initialValue: editing?.toAccount?.id)
    }

    private var parsedAmount: Decimal {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "")) ?? .zero
    }

    private var filteredCategories: [TxnCategory] {
        let target: CategoryType = type == .income ? .income : .expense
        return categories.filter { $0.type == target }
    }

    private var selectedAccount: Account? {
        accounts.first { $0.id == selectedAccountID }
    }

    private var selectedToAccount: Account? {
        accounts.first { $0.id == selectedToAccountID }
    }

    private var selectedCategory: TxnCategory? {
        categories.first { $0.id == selectedCategoryID }
    }

    private var canSave: Bool {
        guard parsedAmount > 0 else { return false }
        guard selectedAccount != nil else { return false }
        switch type {
        case .transfer:
            return selectedToAccount != nil && selectedAccountID != selectedToAccountID
        case .expense, .income:
            return selectedCategory != nil
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases) { txType in
                            Text(txType.displayName).tag(txType)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Amount") {
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.title2.monospacedDigit())
                }

                if type != .transfer {
                    Section("Category") {
                        if filteredCategories.isEmpty {
                            Text("No categories available").foregroundStyle(.secondary)
                        } else {
                            Picker("Category", selection: $selectedCategoryID) {
                                Text("Select…").tag(UUID?.none)
                                ForEach(filteredCategories) { category in
                                    Label(category.name, systemImage: category.icon)
                                        .tag(Optional(category.id))
                                }
                            }
                        }
                    }
                }

                Section(type == .transfer ? "From Account" : "Account") {
                    accountPicker(selection: $selectedAccountID, exclude: nil)
                }

                if type == .transfer {
                    Section("To Account") {
                        accountPicker(selection: $selectedToAccountID, exclude: selectedAccountID)
                    }
                }

                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...3)
                }

                if editing == nil {
                    Section {
                        Toggle("Recurring", isOn: $isRecurring)
                        if isRecurring {
                            Picker("Frequency", selection: $frequency) {
                                ForEach(Frequency.allCases) { freq in
                                    Text(freq.rawValue.capitalized).tag(freq)
                                }
                            }
                            Toggle("Set end date", isOn: $hasEndDate)
                            if hasEndDate {
                                DatePicker("Ends on", selection: $endDate, displayedComponents: .date)
                            }
                        }
                    } header: {
                        Text("Repeat")
                    } footer: {
                        if isRecurring {
                            Text("First occurrence is created immediately. Future ones generate when you open the app.")
                        }
                    }
                }
            }
            .navigationTitle(editing == nil ? "New Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onChange(of: type) { _, _ in
                selectedCategoryID = nil
            }
        }
    }

    @ViewBuilder
    private func accountPicker(selection: Binding<UUID?>, exclude: UUID?) -> some View {
        if accounts.isEmpty {
            Text("No accounts — add one in Wallet first")
                .foregroundStyle(.secondary)
        } else {
            Picker("Account", selection: selection) {
                Text("Select…").tag(UUID?.none)
                ForEach(accounts.filter { $0.id != exclude }) { account in
                    Label(account.name, systemImage: account.icon)
                        .tag(Optional(account.id))
                }
            }
        }
    }

    private func save() {
        guard let account = selectedAccount else { return }
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedNotes = trimmedNotes.isEmpty ? nil : trimmedNotes

        if let existing = editing {
            // Revert old effect, mutate, re-apply new effect.
            existing.revertFromBalances()
            existing.amount = parsedAmount
            existing.type = type
            existing.account = account
            existing.toAccount = type == .transfer ? selectedToAccount : nil
            existing.category = type == .transfer ? nil : selectedCategory
            existing.date = date
            existing.notes = resolvedNotes
            existing.applyToBalances()
        } else if isRecurring {
            let rule = RecurringRule(
                amount: parsedAmount,
                type: type,
                frequency: frequency,
                account: account,
                toAccount: type == .transfer ? selectedToAccount : nil,
                category: type == .transfer ? nil : selectedCategory,
                startDate: date,
                endDate: hasEndDate ? endDate : nil,
                notes: resolvedNotes
            )
            modelContext.insert(rule)
            // Materialize the first (and any past-due) occurrences immediately
            // so the user sees a transaction right away.
            RecurringService.generate(rule, in: modelContext, upTo: Date())
        } else {
            let transaction = Transaction(
                amount: parsedAmount,
                type: type,
                account: account,
                toAccount: type == .transfer ? selectedToAccount : nil,
                category: type == .transfer ? nil : selectedCategory,
                date: date,
                notes: resolvedNotes
            )
            modelContext.insert(transaction)
            transaction.applyToBalances()
        }
        Haptics.notify(.success)
        dismiss()
    }
}

#Preview {
    AddTransactionSheet()
        .modelContainer(for: [Account.self, TxnCategory.self, Transaction.self], inMemory: true)
}

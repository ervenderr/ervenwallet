import SwiftUI
import SwiftData

struct AddTransactionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query(sort: \TxnCategory.sortOrder) private var categories: [TxnCategory]

    @State private var type: TransactionType = .expense
    @State private var amountText: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var selectedCategoryID: UUID?
    @State private var selectedAccountID: UUID?
    @State private var selectedToAccountID: UUID?

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
            }
            .navigationTitle("New Transaction")
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
        let transaction = Transaction(
            amount: parsedAmount,
            type: type,
            account: account,
            toAccount: type == .transfer ? selectedToAccount : nil,
            category: type == .transfer ? nil : selectedCategory,
            date: date,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        modelContext.insert(transaction)
        transaction.applyToBalances()
        dismiss()
    }
}

#Preview {
    AddTransactionSheet()
        .modelContainer(for: [Account.self, TxnCategory.self, Transaction.self], inMemory: true)
}

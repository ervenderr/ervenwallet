import SwiftUI
import SwiftData

struct AddAccountSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var type: AccountType = .cash
    @State private var balanceText: String = ""
    @State private var creditLimitText: String = ""
    @State private var statementDay: Int = 1
    @State private var dueDay: Int = 15

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedBalance: Decimal {
        Decimal(string: balanceText.replacingOccurrences(of: ",", with: "")) ?? .zero
    }

    private var parsedCreditLimit: Decimal? {
        let cleaned = creditLimitText.replacingOccurrences(of: ",", with: "")
        return cleaned.isEmpty ? nil : Decimal(string: cleaned)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Name (e.g. BDO Savings)", text: $name)
                        .textInputAutocapitalization(.words)

                    Picker("Type", selection: $type) {
                        ForEach(AccountType.allCases) { accountType in
                            Label(accountType.displayName, systemImage: accountType.systemImage)
                                .tag(accountType)
                        }
                    }
                }

                Section("Balance") {
                    TextField(
                        type == .creditCard ? "Current debt (₱)" : "Initial balance (₱)",
                        text: $balanceText
                    )
                    .keyboardType(.decimalPad)
                }

                if type == .creditCard {
                    Section("Credit Card Details") {
                        TextField("Credit limit (₱)", text: $creditLimitText)
                            .keyboardType(.decimalPad)

                        Stepper("Statement day: \(statementDay)", value: $statementDay, in: 1...28)
                        Stepper("Due day: \(dueDay)", value: $dueDay, in: 1...28)
                    }
                }
            }
            .navigationTitle("New Account")
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
        }
    }

    private func save() {
        let account = Account(
            name: trimmedName,
            type: type,
            balance: parsedBalance,
            creditLimit: type == .creditCard ? parsedCreditLimit : nil,
            statementDay: type == .creditCard ? statementDay : nil,
            dueDay: type == .creditCard ? dueDay : nil
        )
        modelContext.insert(account)
        dismiss()
    }
}

#Preview {
    AddAccountSheet()
        .modelContainer(for: Account.self, inMemory: true)
}

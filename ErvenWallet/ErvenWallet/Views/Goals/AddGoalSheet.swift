import SwiftUI
import SwiftData

struct AddGoalSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Account.createdAt) private var accounts: [Account]

    @State private var name: String = ""
    @State private var targetText: String = ""
    @State private var initialText: String = ""
    @State private var hasTargetDate: Bool = false
    @State private var targetDate: Date = Date().addingTimeInterval(60 * 60 * 24 * 90)
    @State private var linkedAccountID: UUID?

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedTarget: Decimal {
        Decimal(string: targetText.replacingOccurrences(of: ",", with: "")) ?? .zero
    }

    private var parsedInitial: Decimal {
        Decimal(string: initialText.replacingOccurrences(of: ",", with: "")) ?? .zero
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && parsedTarget > 0
    }

    private var linkedAccount: Account? {
        accounts.first { $0.id == linkedAccountID }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Name (e.g. Emergency Fund)", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Amounts") {
                    TextField("Target amount (₱)", text: $targetText)
                        .keyboardType(.decimalPad)
                    TextField("Already saved (₱, optional)", text: $initialText)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Toggle("Set target date", isOn: $hasTargetDate)
                    if hasTargetDate {
                        DatePicker("Target date", selection: $targetDate, displayedComponents: .date)
                    }
                }

                if !accounts.isEmpty {
                    Section("Linked Account (optional)") {
                        Picker("Account", selection: $linkedAccountID) {
                            Text("None").tag(UUID?.none)
                            ForEach(accounts) { account in
                                Label(account.name, systemImage: account.icon)
                                    .tag(Optional(account.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Goal")
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
        let goal = SavingsGoal(
            name: trimmedName,
            targetAmount: parsedTarget,
            currentAmount: parsedInitial,
            targetDate: hasTargetDate ? targetDate : nil,
            linkedAccount: linkedAccount
        )
        modelContext.insert(goal)
        dismiss()
    }
}

#Preview {
    AddGoalSheet()
        .modelContainer(for: [Account.self, SavingsGoal.self], inMemory: true)
}

import SwiftUI
import SwiftData

struct AddBudgetSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let month: Date

    @Query(sort: \TxnCategory.sortOrder) private var categories: [TxnCategory]
    @Query private var existingBudgets: [Budget]

    @State private var selectedCategoryID: UUID?
    @State private var amountText: String = ""
    @State private var rollover: Bool = false

    private var expenseCategories: [TxnCategory] {
        categories.filter { $0.type == .expense }
    }

    private var availableCategories: [TxnCategory] {
        let usedIDs = Set(existingBudgets
            .filter { $0.month == month }
            .compactMap { $0.category?.id })
        return expenseCategories.filter { !usedIDs.contains($0.id) }
    }

    private var selectedCategory: TxnCategory? {
        categories.first { $0.id == selectedCategoryID }
    }

    private var parsedAmount: Decimal {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "")) ?? .zero
    }

    private var canSave: Bool {
        selectedCategory != nil && parsedAmount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    if availableCategories.isEmpty {
                        Text("All expense categories already have a budget this month.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Category", selection: $selectedCategoryID) {
                            Text("Select…").tag(UUID?.none)
                            ForEach(availableCategories) { category in
                                Label(category.name, systemImage: category.icon)
                                    .tag(Optional(category.id))
                            }
                        }
                    }
                }

                Section("Monthly Limit") {
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.title2.monospacedDigit())
                }

                Section {
                    Toggle("Rollover unspent to next month", isOn: $rollover)
                } footer: {
                    Text("Rollover support is planned — toggle is saved but not yet applied.")
                }
            }
            .navigationTitle("New Budget")
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
        guard let category = selectedCategory else { return }
        let budget = Budget(
            category: category,
            amount: parsedAmount,
            month: month,
            rollover: rollover
        )
        modelContext.insert(budget)
        dismiss()
    }
}

#Preview {
    AddBudgetSheet(month: Date())
        .modelContainer(for: [TxnCategory.self, Budget.self], inMemory: true)
}

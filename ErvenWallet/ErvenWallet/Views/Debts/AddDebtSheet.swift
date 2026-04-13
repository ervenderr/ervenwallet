import SwiftUI
import SwiftData

struct AddDebtSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var direction: DebtDirection = .owed
    @State private var totalText: String = ""
    @State private var rateText: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date().addingTimeInterval(60 * 60 * 24 * 30)
    @State private var notes: String = ""

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedTotal: Decimal {
        Decimal(string: totalText.replacingOccurrences(of: ",", with: "")) ?? .zero
    }

    private var parsedRate: Decimal? {
        let cleaned = rateText.replacingOccurrences(of: ",", with: "")
        return cleaned.isEmpty ? nil : Decimal(string: cleaned)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && parsedTotal > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $direction) {
                        ForEach(DebtDirection.allCases) { d in
                            Text(d.displayName).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Details") {
                    TextField(
                        direction == .owed ? "Creditor (e.g. BPI)" : "Debtor (e.g. Juan)",
                        text: $name
                    )
                    .textInputAutocapitalization(.words)

                    TextField("Total amount (₱)", text: $totalText)
                        .keyboardType(.decimalPad)

                    TextField("Interest rate % (optional)", text: $rateText)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Toggle("Set due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .navigationTitle("New Debt")
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
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let debt = Debt(
            name: trimmedName,
            direction: direction,
            totalAmount: parsedTotal,
            interestRate: parsedRate,
            dueDate: hasDueDate ? dueDate : nil,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        modelContext.insert(debt)
        dismiss()
    }
}

#Preview {
    AddDebtSheet()
        .modelContainer(for: [Debt.self, DebtPayment.self], inMemory: true)
}

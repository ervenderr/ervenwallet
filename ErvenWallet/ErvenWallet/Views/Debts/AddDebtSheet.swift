import SwiftUI
import SwiftData

struct AddDebtSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let editing: Debt?

    @State private var name: String
    @State private var direction: DebtDirection
    @State private var totalText: String
    @State private var rateText: String
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var notes: String

    init(editing: Debt? = nil) {
        self.editing = editing
        _name = State(initialValue: editing?.name ?? "")
        _direction = State(initialValue: editing?.direction ?? .owed)
        _totalText = State(initialValue: editing.map { "\($0.totalAmount)" } ?? "")
        _rateText = State(initialValue: editing?.interestRate.map { "\($0)" } ?? "")
        _hasDueDate = State(initialValue: editing?.dueDate != nil)
        _dueDate = State(initialValue: editing?.dueDate ?? Date().addingTimeInterval(60 * 60 * 24 * 30))
        _notes = State(initialValue: editing?.notes ?? "")
    }

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
            .navigationTitle(editing == nil ? "New Debt" : "Edit Debt")
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
        let resolvedNotes = trimmedNotes.isEmpty ? nil : trimmedNotes
        if let existing = editing {
            existing.name = trimmedName
            existing.directionRaw = direction.rawValue
            // Preserve paid progress: adjust remaining to reflect new total.
            let paid = existing.totalAmount - existing.remainingAmount
            existing.totalAmount = parsedTotal
            existing.remainingAmount = max(parsedTotal - paid, 0)
            existing.interestRate = parsedRate
            existing.dueDate = hasDueDate ? dueDate : nil
            existing.notes = resolvedNotes
        } else {
            let debt = Debt(
                name: trimmedName,
                direction: direction,
                totalAmount: parsedTotal,
                interestRate: parsedRate,
                dueDate: hasDueDate ? dueDate : nil,
                notes: resolvedNotes
            )
            modelContext.insert(debt)
        }
        Haptics.notify(.success)
        dismiss()
    }
}

#Preview {
    AddDebtSheet()
        .modelContainer(for: [Debt.self, DebtPayment.self], inMemory: true)
}

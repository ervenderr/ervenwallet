import SwiftUI
import SwiftData

struct DebtListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Debt.createdAt) private var debts: [Debt]

    @State private var showingAddSheet = false
    @State private var payingDebt: Debt?

    private var iOwe: [Debt] {
        debts.filter { $0.direction == .owed }
    }

    private var owedToMe: [Debt] {
        debts.filter { $0.direction == .owing }
    }

    private var totalOwed: Decimal {
        iOwe.reduce(.zero) { $0 + $1.remainingAmount }
    }

    private var totalOwing: Decimal {
        owedToMe.reduce(.zero) { $0 + $1.remainingAmount }
    }

    var body: some View {
        Group {
            if debts.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Debts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddDebtSheet()
        }
        .sheet(item: $payingDebt) { debt in
            LogPaymentSheet(debt: debt)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No debts tracked", systemImage: "arrow.left.arrow.right.circle")
        } description: {
            Text("Track money you owe and money owed to you.")
        }
    }

    private var list: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("I Owe").font(.caption).foregroundStyle(.secondary)
                        Text(CurrencyFormatter.format(totalOwed))
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(totalOwed > 0 ? Color.red : Color.primary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Owed to Me").font(.caption).foregroundStyle(.secondary)
                        Text(CurrencyFormatter.format(totalOwing))
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(totalOwing > 0 ? Color.green : Color.primary)
                    }
                }
                .padding(.vertical, 4)
            }

            if !iOwe.isEmpty {
                Section("I Owe") {
                    ForEach(iOwe) { debt in
                        DebtRow(debt: debt)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    payingDebt = debt
                                } label: {
                                    Label("Pay", systemImage: "creditcard")
                                }
                                .tint(.green)
                            }
                    }
                    .onDelete { offsets in delete(items: iOwe, at: offsets) }
                }
            }

            if !owedToMe.isEmpty {
                Section("Owed to Me") {
                    ForEach(owedToMe) { debt in
                        DebtRow(debt: debt)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    payingDebt = debt
                                } label: {
                                    Label("Receive", systemImage: "arrow.down.circle")
                                }
                                .tint(.green)
                            }
                    }
                    .onDelete { offsets in delete(items: owedToMe, at: offsets) }
                }
            }
        }
    }

    private func delete(items: [Debt], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
    }
}

private struct DebtRow: View {
    let debt: Debt

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(debt.name, systemImage: debt.direction.systemImage)
                    .font(.body)
                Spacer()
                if debt.isSettled {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }

            ProgressView(value: debt.progress)
                .tint(debt.isSettled ? .green : .accentColor)

            HStack {
                Text("\(CurrencyFormatter.format(debt.paidAmount)) / \(CurrencyFormatter.format(debt.totalAmount))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(CurrencyFormatter.format(debt.remainingAmount)) left")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if let dueDate = debt.dueDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text("Due \(dueDate, format: .dateTime.month().day().year())")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct LogPaymentSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let debt: Debt
    @State private var amountText: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""

    private var parsedAmount: Decimal {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "")) ?? .zero
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(debt.name) {
                    HStack {
                        Text("Remaining")
                        Spacer()
                        Text(CurrencyFormatter.format(debt.remainingAmount))
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Payment") {
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.title2.monospacedDigit())
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .navigationTitle("Log Payment")
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
        let payment = DebtPayment(
            amount: parsedAmount,
            date: date,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        payment.debt = debt
        modelContext.insert(payment)
        debt.remainingAmount = max(debt.remainingAmount - parsedAmount, .zero)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        DebtListView()
            .modelContainer(for: [Debt.self, DebtPayment.self], inMemory: true)
    }
}

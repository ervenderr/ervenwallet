import SwiftUI
import SwiftData

struct DebtListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Debt.createdAt) private var debts: [Debt]

    @State private var showingAddSheet = false
    @State private var payingDebt: Debt?
    @State private var editingDebt: Debt?

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
            AddDebtSheet().themeSheet()
        }
        .sheet(item: $payingDebt) { debt in
            LogPaymentSheet(debt: debt).themeSheet()
        }
        .sheet(item: $editingDebt) { debt in
            AddDebtSheet(editing: debt).themeSheet()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No debts tracked", systemImage: "arrow.left.arrow.right.circle")
        } description: {
            Text("Track money you owe and money owed to you.")
        } actions: {
            Button {
                showingAddSheet = true
                Haptics.impact(.light)
            } label: {
                Label("Add Debt", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Palette.primary)
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                summaryCard
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.sm)

                if !iOwe.isEmpty {
                    debtSection(title: "I Owe", debts: iOwe)
                }
                if !owedToMe.isEmpty {
                    debtSection(title: "Owed to Me", debts: owedToMe)
                }
                Spacer(minLength: Theme.Spacing.xl)
            }
        }
        .background(Theme.Palette.surface)
    }

    private var summaryCard: some View {
        HStack(spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("I Owe")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.75))
                Text(CurrencyFormatter.format(totalOwed))
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: totalOwed)
            }
            Spacer()
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 36)
            Spacer()
            VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                Text("Owed to Me")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.75))
                Text(CurrencyFormatter.format(totalOwing))
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Theme.Palette.accentLight)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: totalOwing)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Theme.Gradients.hero)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        .themeShadow(Theme.Shadow.hero)
    }

    private func debtSection(title: String, debts: [Debt]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, Theme.Spacing.lg)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(debts) { debt in
                    DebtRow(debt: debt)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Palette.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                        .onTapGesture {
                            payingDebt = debt
                            Haptics.impact(.light)
                        }
                        .contextMenu {
                            Button {
                                payingDebt = debt
                            } label: {
                                Label("Log Payment", systemImage: "creditcard")
                            }
                            Button {
                                editingDebt = debt
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                modelContext.delete(debt)
                                Haptics.impact(.medium)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
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
                .tint(debt.isSettled ? Theme.Palette.income : Theme.Palette.primary)

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

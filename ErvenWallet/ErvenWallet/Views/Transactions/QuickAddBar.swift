import SwiftUI
import SwiftData

/// A single-line text input above the Transactions list. Type "lunch 250"
/// and hit return to log a transaction in one step. Unparseable input opens
/// the full Add sheet prefilled with whatever was extracted.
struct QuickAddBar: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query(sort: \TxnCategory.sortOrder) private var categories: [TxnCategory]

    @State private var text: String = ""
    @State private var showingFallback = false
    @State private var fallbackDraft: QuickAddParser.Draft?
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .foregroundStyle(Theme.Palette.accent)
                .font(.subheadline.weight(.semibold))

            TextField("Try: lunch 250", text: $text)
                .focused($focused)
                .submitLabel(.send)
                .onSubmit(handleSubmit)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.md)
        .background(Theme.Palette.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(Theme.Palette.accent.opacity(focused ? 0.4 : 0), lineWidth: 1)
        )
        .sheet(isPresented: $showingFallback, onDismiss: { fallbackDraft = nil }) {
            if let draft = fallbackDraft {
                AddTransactionSheet(prefill: draft)
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func handleSubmit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let draft = QuickAddParser.parse(trimmed)

        guard let amount = draft.amount, amount > 0,
              let account = accounts.first else {
            openFallback(with: draft)
            return
        }

        let category = resolveCategory(draft: draft)
        guard draft.type == .income || category != nil else {
            openFallback(with: draft)
            return
        }

        let transaction = Transaction(
            amount: amount,
            type: draft.type == .income ? .income : .expense,
            account: account,
            toAccount: nil,
            category: category,
            date: draft.date,
            notes: draft.notes
        )
        modelContext.insert(transaction)
        transaction.applyToBalances()

        Haptics.notify(.success)
        text = ""
        focused = false
    }

    private func resolveCategory(draft: QuickAddParser.Draft) -> TxnCategory? {
        let target: CategoryType = draft.type == .income ? .income : .expense
        let pool = categories.filter { $0.type == target }

        if let keyword = draft.categoryName {
            if let match = pool.first(where: { $0.name.lowercased().contains(keyword) }) {
                return match
            }
        }
        return nil
    }

    private func openFallback(with draft: QuickAddParser.Draft) {
        fallbackDraft = draft
        showingFallback = true
    }

}

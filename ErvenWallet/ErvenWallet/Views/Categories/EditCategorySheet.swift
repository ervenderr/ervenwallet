import SwiftUI
import SwiftData

struct EditCategorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allCategories: [TxnCategory]

    let editing: TxnCategory?
    let initialType: CategoryType

    @State private var name: String
    @State private var icon: String
    @State private var type: CategoryType

    init(type: CategoryType) {
        self.editing = nil
        self.initialType = type
        _name = State(initialValue: "")
        _icon = State(initialValue: "tag.fill")
        _type = State(initialValue: type)
    }

    init(editing: TxnCategory) {
        self.editing = editing
        self.initialType = editing.type
        _name = State(initialValue: editing.name)
        _icon = State(initialValue: editing.icon)
        _type = State(initialValue: editing.type)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty
    }

    private static let iconChoices: [String] = [
        "fork.knife", "cart.fill", "car.fill", "bus.fill", "fuelpump.fill",
        "house.fill", "bolt.fill", "drop.fill", "wifi", "phone.fill",
        "bag.fill", "tshirt.fill", "gift.fill", "heart.fill", "cross.case.fill",
        "pills.fill", "stethoscope", "book.fill", "graduationcap.fill",
        "gamecontroller.fill", "tv.fill", "film.fill", "music.note",
        "airplane", "figure.walk", "dumbbell.fill", "pawprint.fill",
        "tray.fill", "doc.fill", "creditcard.fill", "banknote.fill",
        "dollarsign.circle.fill", "chart.line.uptrend.xyaxis",
        "briefcase.fill", "hammer.fill", "wrench.fill", "leaf.fill",
        "cup.and.saucer.fill", "birthday.cake.fill", "party.popper.fill",
        "tag.fill", "star.fill",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Type") {
                    Picker("Type", selection: $type) {
                        Text("Expense").tag(CategoryType.expense)
                        Text("Income").tag(CategoryType.income)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                        ForEach(Self.iconChoices, id: \.self) { choice in
                            Button {
                                icon = choice
                                Haptics.impact(.light)
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(icon == choice ? Theme.Palette.primary.opacity(0.2) : Color.secondary.opacity(0.08))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: choice)
                                        .foregroundStyle(icon == choice ? Theme.Palette.primary : .primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                }
            }
            .navigationTitle(editing == nil ? "New Category" : "Edit Category")
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
        if let existing = editing {
            existing.name = trimmedName
            existing.icon = icon
            existing.typeRaw = type.rawValue
        } else {
            let sortOrder = (allCategories.map { $0.sortOrder }.max() ?? 0) + 1
            let category = TxnCategory(
                name: trimmedName,
                icon: icon,
                type: type,
                sortOrder: sortOrder
            )
            modelContext.insert(category)
        }
        Haptics.notify(.success)
        dismiss()
    }
}

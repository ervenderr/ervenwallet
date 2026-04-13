import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TxnCategory.sortOrder) private var categories: [TxnCategory]

    @State private var showingAddSheet = false
    @State private var editingCategory: TxnCategory?
    @State private var filter: CategoryType = .expense

    private var filtered: [TxnCategory] {
        categories.filter { $0.type == filter }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Type", selection: $filter) {
                Text("Expense").tag(CategoryType.expense)
                Text("Income").tag(CategoryType.income)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.xs)

            if filtered.isEmpty {
                ContentUnavailableView(
                    "No \(filter == .expense ? "expense" : "income") categories",
                    systemImage: "tag"
                )
                .frame(maxHeight: .infinity)
            } else {
                list
            }
        }
        .background(Theme.Palette.surface)
        .navigationTitle("Categories")
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
            EditCategorySheet(type: filter).themeSheet()
        }
        .sheet(item: $editingCategory) { category in
            EditCategorySheet(editing: category).themeSheet()
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(filtered) { category in
                    CategoryRow(category: category)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Palette.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingCategory = category
                            Haptics.impact(.light)
                        }
                        .contextMenu {
                            Button {
                                editingCategory = category
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                modelContext.delete(category)
                                Haptics.impact(.medium)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                Spacer(minLength: Theme.Spacing.xl)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.sm)
        }
    }
}

private struct CategoryRow: View {
    let category: TxnCategory

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(CategoryColor.color(for: category.name).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: category.icon)
                    .foregroundStyle(CategoryColor.color(for: category.name))
            }
            Text(category.name)
                .font(.body.weight(.medium))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

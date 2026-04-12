import Foundation
import SwiftData

enum DefaultCategories {
    struct Seed {
        let name: String
        let icon: String
        let colorHex: String
        let type: CategoryType
    }

    static let all: [Seed] = [
        // Expenses (PHP context)
        Seed(name: "Food & Dining", icon: "fork.knife", colorHex: "#FF9500", type: .expense),
        Seed(name: "Groceries", icon: "cart.fill", colorHex: "#34C759", type: .expense),
        Seed(name: "Transport", icon: "car.fill", colorHex: "#5AC8FA", type: .expense),
        Seed(name: "Utilities", icon: "bolt.fill", colorHex: "#FFCC00", type: .expense),
        Seed(name: "Rent", icon: "house.fill", colorHex: "#AF52DE", type: .expense),
        Seed(name: "Shopping", icon: "bag.fill", colorHex: "#FF2D55", type: .expense),
        Seed(name: "Health", icon: "cross.case.fill", colorHex: "#FF3B30", type: .expense),
        Seed(name: "Entertainment", icon: "film.fill", colorHex: "#5856D6", type: .expense),
        Seed(name: "Education", icon: "book.fill", colorHex: "#007AFF", type: .expense),
        Seed(name: "Personal Care", icon: "scissors", colorHex: "#FF9500", type: .expense),
        Seed(name: "Subscriptions", icon: "repeat", colorHex: "#5856D6", type: .expense),
        Seed(name: "Credit Card Payment", icon: "creditcard.fill", colorHex: "#8E8E93", type: .expense),
        Seed(name: "Forex/Trading", icon: "chart.line.uptrend.xyaxis", colorHex: "#34C759", type: .expense),
        Seed(name: "Miscellaneous", icon: "ellipsis.circle", colorHex: "#8E8E93", type: .expense),

        // Income
        Seed(name: "Salary", icon: "briefcase.fill", colorHex: "#34C759", type: .income),
        Seed(name: "Freelance", icon: "laptopcomputer", colorHex: "#5AC8FA", type: .income),
        Seed(name: "Side Income", icon: "dollarsign.circle", colorHex: "#FFCC00", type: .income),
        Seed(name: "Dividends", icon: "chart.pie.fill", colorHex: "#AF52DE", type: .income),
        Seed(name: "Trading Gains", icon: "arrow.up.right.circle", colorHex: "#34C759", type: .income),
        Seed(name: "Refunds", icon: "arrow.uturn.left.circle", colorHex: "#FF9500", type: .income),
        Seed(name: "Other", icon: "questionmark.circle", colorHex: "#8E8E93", type: .income)
    ]

    /// Inserts default categories if none exist yet. Safe to call on every launch.
    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<TxnCategory>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for (index, seed) in all.enumerated() {
            let category = TxnCategory(
                name: seed.name,
                icon: seed.icon,
                colorHex: seed.colorHex,
                type: seed.type,
                sortOrder: index
            )
            context.insert(category)
        }
    }
}

import Foundation

/// Parses a free-form quick-add line like "lunch 250" or "uber 120 yesterday"
/// into a structured draft transaction. Pure, rules-based, no ML.
///
/// Strategy:
///   1. Pull the first number token → amount
///   2. Pull date hints ("today", "yesterday", weekday names) → date
///   3. Remaining words → try to match a category by name or alias
///   4. Whatever's left → notes
enum QuickAddParser {

    struct Draft {
        var amount: Decimal?
        var date: Date
        var categoryName: String?
        var notes: String?
        var type: ParsedType
    }

    enum ParsedType {
        case expense
        case income
    }

    /// Common aliases → canonical category keyword. The category lookup then
    /// matches these keywords against actual TxnCategory.name case-insensitively.
    private static let aliases: [String: String] = [
        // Food
        "lunch": "food", "dinner": "food", "breakfast": "food",
        "snack": "food", "coffee": "food", "meal": "food",
        "jollibee": "food", "mcdo": "food", "mcdonalds": "food",
        "chowking": "food", "starbucks": "food",
        // Transport
        "uber": "transport", "grab": "transport", "taxi": "transport",
        "jeep": "transport", "jeepney": "transport", "tricycle": "transport",
        "bus": "transport", "mrt": "transport", "lrt": "transport",
        "gas": "transport", "fuel": "transport", "gasoline": "transport",
        "fare": "transport",
        // Shopping
        "shopee": "shopping", "lazada": "shopping", "sm": "shopping",
        "mall": "shopping",
        // Bills
        "meralco": "bills", "electric": "bills", "electricity": "bills",
        "water": "bills", "maynilad": "bills", "manilawater": "bills",
        "wifi": "bills", "internet": "bills", "pldt": "bills",
        "globe": "bills", "smart": "bills", "converge": "bills",
        "rent": "bills",
        // Entertainment
        "netflix": "entertainment", "spotify": "entertainment",
        "movie": "entertainment", "cinema": "entertainment",
        "game": "entertainment",
        // Health
        "medicine": "health", "pharmacy": "health", "doctor": "health",
        "hospital": "health", "mercury": "health",
        // Income
        "salary": "salary", "payroll": "salary", "pay": "salary",
        "bonus": "bonus", "gift": "gift", "refund": "refund",
    ]

    /// Words that signal the transaction is income rather than expense.
    private static let incomeKeywords: Set<String> = [
        "salary", "payroll", "pay", "bonus", "gift", "refund", "received"
    ]

    /// Parse an input string into a draft. Returns a draft with whatever
    /// could be inferred; nil fields are left for the user to fill in.
    static func parse(_ input: String, calendar: Calendar = .current, today: Date = Date()) -> Draft {
        let tokens = input
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber && $0 != "." }
            .map(String.init)

        var amount: Decimal?
        var date = today
        var keywordHits: [String] = []
        var leftover: [String] = []
        var isIncome = false

        for token in tokens {
            if amount == nil, let parsed = decimalToken(token) {
                amount = parsed
                continue
            }
            if let dateHint = dateHint(for: token, calendar: calendar, today: today) {
                date = dateHint
                continue
            }
            if incomeKeywords.contains(token) {
                isIncome = true
            }
            if let canonical = aliases[token] {
                keywordHits.append(canonical)
                continue
            }
            leftover.append(token)
        }

        let categoryName = keywordHits.first
        let notes = leftover.isEmpty ? nil : leftover.joined(separator: " ").trimmingCharacters(in: .whitespaces)

        return Draft(
            amount: amount,
            date: date,
            categoryName: categoryName,
            notes: notes?.isEmpty == true ? nil : notes,
            type: isIncome ? .income : .expense
        )
    }

    private static func decimalToken(_ token: String) -> Decimal? {
        // Accept plain digits and digits with a single decimal separator.
        guard token.first?.isNumber == true else { return nil }
        let cleaned = token.replacingOccurrences(of: ",", with: "")
        return Decimal(string: cleaned)
    }

    private static func dateHint(for token: String, calendar: Calendar, today: Date) -> Date? {
        switch token {
        case "today":
            return today
        case "yesterday":
            return calendar.date(byAdding: .day, value: -1, to: today)
        case "tomorrow":
            return calendar.date(byAdding: .day, value: 1, to: today)
        default:
            break
        }
        // Weekday names: "monday" → most recent Monday on or before today.
        let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        if let weekdayIndex = weekdays.firstIndex(of: token) {
            let targetWeekday = weekdayIndex + 1 // Calendar uses 1-based, 1 = Sunday
            let todayWeekday = calendar.component(.weekday, from: today)
            var delta = todayWeekday - targetWeekday
            if delta < 0 { delta += 7 }
            return calendar.date(byAdding: .day, value: -delta, to: today)
        }
        return nil
    }
}

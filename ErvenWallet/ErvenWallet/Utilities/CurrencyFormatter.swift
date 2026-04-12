import Foundation

enum CurrencyFormatter {
    static let php: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PHP"
        formatter.currencySymbol = "₱"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    static func format(_ amount: Decimal, currency: String = "PHP") -> String {
        let formatter: NumberFormatter
        if currency == "PHP" {
            formatter = php
        } else {
            formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currency
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
        }
        return formatter.string(from: amount as NSDecimalNumber) ?? "₱0.00"
    }
}

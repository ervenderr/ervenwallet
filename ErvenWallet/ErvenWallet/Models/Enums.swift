import Foundation

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case cash
    case bank
    case eWallet
    case creditCard
    case investment

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cash: "Cash"
        case .bank: "Bank"
        case .eWallet: "E-Wallet"
        case .creditCard: "Credit Card"
        case .investment: "Investment"  
        }
    }

    var systemImage: String {
        switch self {
        case .cash: "banknote"
        case .bank: "building.columns"
        case .eWallet: "iphone"
        case .creditCard: "creditcard"
        case .investment: "chart.line.uptrend.xyaxis"
        }
    }
}

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case expense
    case income
    case transfer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .expense: "Expense"
        case .income: "Income"
        case .transfer: "Transfer"
        }
    }
}

enum CategoryType: String, Codable, CaseIterable {
    case expense
    case income
}

enum Frequency: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case biweekly
    case monthly
    case yearly

    var id: String { rawValue }
}

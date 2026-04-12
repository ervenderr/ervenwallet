import SwiftUI
import SwiftData

struct WalletView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @State private var showingAddSheet = false

    private var netWorth: Decimal {
        accounts.reduce(Decimal.zero) { $0 + $1.balance }
    }

    var body: some View {
        NavigationStack {
            Group {
                if accounts.isEmpty {
                    emptyState
                } else {
                    accountsList
                }
            }
            .navigationTitle("Wallet")
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
                AddAccountSheet()
            }
        }
    }

    private func deleteAccounts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(accounts[index])
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No accounts yet", systemImage: "wallet.pass")
        } description: {
            Text("Add your first account to start tracking your money.")
        }
    }

    private var accountsList: some View {
        List {
            Section {
                HStack {
                    Text("Net Worth")
                        .font(.headline)
                    Spacer()
                    Text(CurrencyFormatter.format(netWorth))
                        .font(.headline)
                        .foregroundStyle(netWorth >= 0 ? Color.primary : Color.red)
                }
            }

            Section("Accounts") {
                ForEach(accounts) { account in
                    AccountRow(account: account)
                }
                .onDelete(perform: deleteAccounts)
            }
        }
    }
}

private struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack {
            Image(systemName: account.icon)
                .frame(width: 32, height: 32)
                .foregroundStyle(.tint)
            VStack(alignment: .leading) {
                Text(account.name)
                Text(account.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(CurrencyFormatter.format(account.balance, currency: account.currency))
                .font(.body.monospacedDigit())
        }
    }
}

#Preview {
    WalletView()
        .modelContainer(for: Account.self, inMemory: true)
}

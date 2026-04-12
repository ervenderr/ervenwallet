import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            WalletView()
                .tabItem {
                    Label("Wallet", systemImage: "wallet.pass")
                }

            TransactionListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
                }

            BudgetOverviewView()
                .tabItem {
                    Label("Budget", systemImage: "chart.pie")
                }

            GoalsListView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle")
                }
        }
        .task {
            DefaultCategories.seedIfNeeded(in: modelContext)
        }
    }
}

private struct PlaceholderTab: View {
    let title: String
    let systemImage: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label(title, systemImage: systemImage)
            } description: {
                Text("Coming soon.")
            }
            .navigationTitle(title)
        }
    }
}

#Preview {
    RootView()
}

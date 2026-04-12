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

            PlaceholderTab(title: "Budget", systemImage: "chart.pie")
                .tabItem {
                    Label("Budget", systemImage: "chart.pie")
                }

            PlaceholderTab(title: "Goals", systemImage: "target")
                .tabItem {
                    Label("Goals", systemImage: "target")
                }

            PlaceholderTab(title: "More", systemImage: "ellipsis.circle")
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

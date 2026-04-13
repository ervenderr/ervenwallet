import SwiftUI
import SwiftData

@main
struct ErvenWalletApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
            TxnCategory.self,
            Transaction.self,
            Budget.self,
            SavingsGoal.self,
            Debt.self,
            DebtPayment.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

import SwiftUI
import SwiftData

struct MoreView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            List {
                Section("Data") {
                    Button {
                        exportData()
                    } label: {
                        Label("Export to JSON", systemImage: "square.and.arrow.up")
                    }

                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Share Last Export", systemImage: "paperplane")
                        }
                    }
                }

                Section("About") {
                    LabeledContent("App", value: "ErvenWallet")
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Made by", value: "ervenderr")
                }
            }
            .navigationTitle("More")
            .alert("Export Failed", isPresented: $showingError, presenting: exportError) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error)
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    private func exportData() {
        do {
            let url = try DataExportService.writeExportFile(from: modelContext)
            exportURL = url
        } catch {
            exportError = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    MoreView()
        .modelContainer(for: [Account.self, Category.self, Transaction.self], inMemory: true)
}

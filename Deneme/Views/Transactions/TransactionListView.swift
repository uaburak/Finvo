import SwiftUI

struct TransactionListView: View {
    @StateObject private var viewModel = TransactionListViewModel()
    // In a real app, you would pass the selected wallet ID from a global state/environment.
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Filtre", selection: Binding(
                    get: { viewModel.filterType },
                    set: { viewModel.updateFilter($0) }
                )) {
                    Text("Tümü").tag(Optional<TransactionType>.none)
                    Text("Gelir").tag(Optional(TransactionType.income))
                    Text("Gider").tag(Optional(TransactionType.expense))
                }
                .pickerStyle(.segmented)
                .padding()
                
                List {
                    ForEach(viewModel.transactions) { transaction in
                        TransactionRow(transaction: transaction)
                            .onAppear {
                                if transaction == viewModel.transactions.last {
                                    Task { await viewModel.fetchNextPage() }
                                }
                            }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.refresh()
                }
                .onAppear {
                    // Determine wallet ID
                    if let walletId = FirestoreService.shared.wallets.first?.id {
                        if viewModel.transactions.isEmpty {
                            Task { await viewModel.loadInitialData(walletId: walletId) }
                        }
                    }
                }
            } // End of VStack
            .navigationTitle("İşlemler")
        } // End of NavigationStack
    }
}

#Preview {
    TransactionListView()
}

import SwiftUI

struct TransactionListView: View {
    @StateObject private var viewModel = TransactionListViewModel()
    @EnvironmentObject var walletManager: WalletManager
    @State private var showCreateWallet = false
    @State private var showFilterSheet = false
    @State private var filter = TransactionFilter() // Default filter
    
    var body: some View {
        NavigationStack {
            VStack {
                if walletManager.selectedWallet == nil {
                    VStack {
                        Spacer()
                        Text("Cüzdan seçilmedi")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {

                    if let error = viewModel.errorMessage {
                        VStack {
                            Text("Hata: \(error)")
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding()
                                .multilineTextAlignment(.center)
                            
                            if error.contains("requires an index") {
                                Link("Veritabanı İndeksini Oluştur", destination: URL(string: "https://console.firebase.google.com/u/0/project/finvoapp-ad1a6/firestore/indexes")!)
                                    .buttonStyle(.borderedProminent)
                                    .tint(.blue)
                                    .padding(.bottom)
                                Text("(Linke tıkladıktan sonra açılan sayfada 'Create Index' butonuna basın)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if viewModel.transactions.isEmpty && !viewModel.isLoading {
                        VStack {
                            Spacer()
                            Image(systemName: "list.clipboard")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                                .padding()
                            Text("İşlem bulunamadı.")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(viewModel.transactions) { transaction in
                                TransactionRow(transaction: transaction)
                                    // Pagination removed for real-time stability

                            }
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .listStyle(.plain)
                        }
                    }
                }
            .navigationTitle("İşlemler")
            .toolbar {
                // Principal: Segmented Control (Filter Type)
                ToolbarItem(placement: .principal) {
                    Picker("Filtre", selection: Binding(
                        get: { viewModel.filterType },
                        set: { viewModel.updateFilter($0) }
                    )) {
                        Text("Tümü").tag(Optional<TransactionType>.none)
                        Text("Gelir").tag(Optional(TransactionType.income))
                        Text("Gider").tag(Optional(TransactionType.expense))
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                
                // Trailing: Filter Button
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                TransactionFilterView(filter: $filter) // We need state for this
            }
            .onAppear {
                if let wallet = walletManager.selectedWallet {
                    viewModel.loadInitialData(for: wallet)
                }
            }
            .onChange(of: walletManager.selectedWallet) { _, newWallet in
                if let wallet = newWallet {
                    viewModel.loadInitialData(for: wallet)
                }
            }
        }
    }
}

#Preview {
    TransactionListView()
        .environmentObject(WalletManager.shared)
}

import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @EnvironmentObject var walletManager: WalletManager
    @State private var selectedChart = 0 // 0: Pie, 1: Bar
    @State private var showCreateWallet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Picker("Grafik", selection: $selectedChart) {
                        Text("Dağılım").tag(0)
                        Text("Aylık").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(height: 200)
                    } else if walletManager.selectedWallet == nil {
                        VStack {
                            Text("Cüzdan seçilmedi")
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 200)
                    } else if selectedChart == 0 {
                        // Pie Chart
                        if viewModel.chartData.isEmpty {
                            Text("Veri yok")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            Chart(viewModel.chartData) { item in
                                SectorMark(
                                    angle: .value("Tutar", item.value),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .cornerRadius(5)
                                .foregroundStyle(item.color)
                                .annotation(position: .overlay) {
                                    Text(item.category)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(height: 300)
                            .padding()
                        }
                    } else {
                        // Bar Chart
                        if viewModel.monthlyData.isEmpty {
                             Text("Veri yok")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            Chart(viewModel.monthlyData) { item in
                                BarMark(
                                    x: .value("Ay", item.month),
                                    y: .value("Gelir", item.income)
                                )
                                .foregroundStyle(.green)
                                
                                BarMark(
                                    x: .value("Ay", item.month),
                                    y: .value("Gider", item.expense)
                                )
                                .foregroundStyle(.red)
                            }
                            .frame(height: 300)
                            .padding()
                        }
                    }
                    
                    // Insights / Summary
                    VStack(alignment: .leading, spacing: 5) {
                        Text("İçgörüler")
                            .font(.headline)
                        Text(selectedChart == 0 ? "En çok harcamayı \(viewModel.chartData.first?.category ?? "-") kategorisine yaptın." : "Son 6 ayın gelir/gider karşılaştırması.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Analiz")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Menu {
                        ForEach(walletManager.wallets) { wallet in
                            Button {
                                walletManager.selectWallet(wallet)
                            } label: {
                                HStack {
                                    Text(wallet.name)
                                    if walletManager.selectedWallet?.id == wallet.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        Button {
                            showCreateWallet = true
                        } label: {
                            Label("Yeni Cüzdan Oluştur", systemImage: "plus.circle")
                        }
                        
                    } label: {
                        HStack {
                            Text(walletManager.selectedWallet?.name ?? "Cüzdan Seç")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let wallet = walletManager.selectedWallet, let walletId = wallet.id {
                        if let exportURL = viewModel.exportURL {
                            ShareLink(item: exportURL) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        } else {
                            Button {
                                Task {
                                    viewModel.exportURL = await viewModel.createExportFile(walletId: walletId)
                                }
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateWallet) {
                CreateWalletView()
            }
            .onAppear {
                if let wallet = walletManager.selectedWallet {
                    Task { await viewModel.fetchData(for: wallet) }
                }
            }
            .onChange(of: walletManager.selectedWallet) { _, newWallet in
                if let wallet = newWallet {
                    Task { await viewModel.fetchData(for: wallet) }
                }
            }
        }
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(WalletManager.shared)
}

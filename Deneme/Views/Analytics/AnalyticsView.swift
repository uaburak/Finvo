import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var selectedChart = 0 // 0: Pie, 1: Bar
    
    // We assume we have access to the selected wallet ID globally or pass it in.
    // For MVP, using shared instance access via View logic or injection
    var walletId: String? {
        FirestoreService.shared.wallets.first?.id
    }
    
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
                    
                    // Insights / Summary (Simple placeholder)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let walletId = walletId {
                        // In iOS 16+, ShareLink is preferred.
                        // We need to generate the file first. 
                        // ShareLink requires the item to be ready or a closure?
                        // Actually ShareLink `item` property takes the URL directly.
                        // To make it async, we can wrap the generation.
                        
                        // Simplifying: Button that generates then shares via sheet?
                        // Or ShareLink with a placeholder that regenerates?
                        // Let's use a button that triggers generation, then presents ShareSheet custom or ShareLink if possible.
                        // ShareLink is easiest if we have the URL.
                        
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
            .onAppear {
                if let id = walletId {
                    Task { await viewModel.fetchData(walletId: id) }
                }
            }
        }
    }
}

#Preview {
    AnalyticsView()
}

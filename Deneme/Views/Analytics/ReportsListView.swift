import SwiftUI

struct ReportsListView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @EnvironmentObject var walletManager: WalletManager
    
    @State private var showCreateSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Raporlar yükleniyor...")
                } else if viewModel.reports.isEmpty {
                    ContentUnavailableView("Henüz Rapor Yok", systemImage: "doc.text.magnifyingglass", description: Text("Geçmiş analizlerinizi saklamak için yeni bir rapor oluşturun."))
                } else {
                    List {
                        ForEach(viewModel.reports) { report in
                            NavigationLink(destination: ReportDetailView(report: report)) {
                                ReportRow(report: report)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Raporlarım")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateReportSheet(item: $showCreateSheet, viewModel: viewModel)
            }
            .onAppear {
                if let walletId = walletManager.selectedWallet?.id {
                    Task { await viewModel.fetchReports(walletId: walletId) }
                }
            }
        }
    }
}

struct ReportRow: View {
    let report: Report
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(report.rangeType.rawValue)
                    .font(.headline)
                Text(report.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(report.totalExpense.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .bold()
                
                if report.netBalance >= 0 {
                    Text("+\(report.netBalance.formatted(.currency(code: "TRY").precision(.fractionLength(0))))")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text(report.netBalance.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct CreateReportSheet: View {
    @Binding var item: Bool
    @ObservedObject var viewModel: ReportsViewModel
    @EnvironmentObject var walletManager: WalletManager
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Rapor Aralığı Seçin") {
                    Picker("Dönem", selection: $viewModel.selectedRange) {
                        ForEach(ReportRangeType.allCases.filter { $0 != .custom }, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button {
                        if let wallet = walletManager.selectedWallet {
                            Task {
                                let success = await viewModel.createSnapshot(wallet: wallet, range: viewModel.selectedRange)
                                if success {
                                    item = false
                                }
                            }
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Rapor Oluştur")
                                .frame(maxWidth: .infinity)
                                .bold()
                        }
                    }
                    .listRowBackground(Color.blue)
                    .foregroundColor(.white)
                    .disabled(viewModel.isLoading)
                } footer: {
                    Text("Seçilen aralıktaki tüm işlemler analiz edilip kaydedilecektir.")
                }
            }
            .navigationTitle("Yeni Rapor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { item = false }
                }
            }
        }
        .presentationDetents([.height(300)])
    }
}

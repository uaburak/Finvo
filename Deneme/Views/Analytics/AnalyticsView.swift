import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @EnvironmentObject var walletManager: WalletManager
    
    // Hub State
    @State private var showCreateWallet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Header & Time Picker
                    headerView
                    
                    // 2. Quick Access Cards
                    quickAccessSection
                    
                    // 3. Main Overview Content
                    if walletManager.selectedWallet == nil {
                        ContentUnavailableView("Cüzdan Seçilmedi", systemImage: "wallet.pass")
                            .padding(.top, 40)
                    } else {
                        OverviewView(viewModel: viewModel)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Analiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: ReportsListView().environmentObject(walletManager)) {
                        Text("Raporlarım")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if let wallet = walletManager.selectedWallet, let walletId = wallet.id {
                        Button {
                            Task {
                                await exportWalletData(walletId: walletId)
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(item: $viewModel.exportItem) { item in
                 ShareSheet(activityItems: [item.url])
            }
            .onAppear {
                if let wallet = walletManager.selectedWallet {
                    Task { await fetchWalletData(wallet) }
                }
            }
            .onChange(of: walletManager.selectedWallet) { _, newWallet in
                if let wallet = newWallet {
                    Task { await fetchWalletData(wallet) }
                }
            }
        }
    }
    
    private func fetchWalletData(_ wallet: Wallet) async {
        await viewModel.fetchData(for: wallet)
    }
    
    private func exportWalletData(walletId: String) async {
        viewModel.exportItem = await viewModel.createExportFile(walletId: walletId)
    }
    
    @Namespace private var namespace
    
    // MARK: - Components
    
    private var headerView: some View {
        VStack(spacing: 20) {
            // Net Balance Card (Moved from Overview)
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Net Durum")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text(viewModel.balance.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText()) // Added animation
                        .animation(.snappy, value: viewModel.balance)
                }
                
                Spacer()
                
                Image(systemName: viewModel.balance >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(20)
            .background {
                LinearGradient(
                    colors: viewModel.balance >= 0 ? [Color.green, Color.green.opacity(0.7)] : [Color.red, Color.red.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .cornerRadius(20)
            .shadow(color: (viewModel.balance >= 0 ? Color.green : Color.red).opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Custom Time Picker
            HStack(spacing: 0) {
                ForEach(AnalyticsTimeRange.allCases, id: \.self) { range in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedTimeRange = range
                        }
                    } label: {
                        Text(range.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(viewModel.selectedTimeRange == range ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background {
                                if viewModel.selectedTimeRange == range {
                                    Capsule()
                                        .fill(Color.blue) // Theme Color
                                        .matchedGeometryEffect(id: "TimeRangePicker", in: namespace)
                                }
                            }
                    }
                }
            }
            .padding(4)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
    }
    
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 0) { // spacing changed to 0 as title removed, but not critical
            HStack(spacing: 12) {
                // 1. Categories
                NavigationLink(destination: CategoriesBreakdownView(viewModel: viewModel)) {
                    QuickAccessCard(
                        title: "Kategoriler",
                        icon: "chart.pie.fill",
                        color: .orange
                    )
                }
                
                // 2. History
                NavigationLink(destination: HistoryTrendView(viewModel: viewModel)) {
                    QuickAccessCard(
                        title: "Geçmiş",
                        icon: "clock.arrow.circlepath",
                        color: .blue
                    )
                }
                
                // 3. Comparison (Shared only)
                if walletManager.selectedWallet?.type == .shared {
                    NavigationLink(destination: ComparisonView(viewModel: viewModel)) {
                        QuickAccessCard(
                            title: "Karşılaştırma",
                            icon: "person.2.fill",
                            color: .purple
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Subviews

struct OverviewView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @EnvironmentObject var walletManager: WalletManager
    
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.totalExpense > 0 {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(viewModel.isExpenseIncreased ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: viewModel.isExpenseIncreased ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                            .foregroundStyle(viewModel.isExpenseIncreased ? .orange : .green)
                            .font(.title3)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.isExpenseIncreased ? "Harcamalar Arttı" : "Tasarruf Modu")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Geçen döneme göre %\(String(format: "%.0f", viewModel.expenseChangePercentage)) \(viewModel.isExpenseIncreased ? "artış" : "azalış") var.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                .padding(.horizontal)
            }
            
            // Key Metrics
            HStack(spacing: 16) {
                ModernMetricTile(
                    title: "Günlük Ort.",
                    value: viewModel.averageDailySetting.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                    icon: "calendar.badge.clock",
                    color: .blue
                )
                
                ModernMetricTile(
                    title: "En Büyük İşlem",
                    value: viewModel.largestTransaction?.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))) ?? "0 ₺",
                    icon: "tag.fill",
                    color: .purple
                )
            }
            .padding(.horizontal)
            
            // Shared Wallet Chart (if applicable)
            if let wallet = walletManager.selectedWallet, wallet.members.count > 1 {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Üye Harcamaları", systemImage: "person.2.fill")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart(viewModel.memberData) { item in
                        BarMark(
                            x: .value("Tutar", item.value),
                            y: .value("Üye", item.username)
                        )
                        .foregroundStyle(item.color.gradient)
                        .cornerRadius(4)
                    }
                    .frame(height: 150)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)
                }
            }
        }
    }
}

// Helper View for Overview
struct ModernMetricTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 110)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.1), lineWidth: 1)
        )
    }
}

struct CategoriesBreakdownView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var animateChart = false
    
    var body: some View {
        VStack(spacing: 24) {
             // Interactive Donut Chart
            chartSection
            
            // Interactive List
            listSection
        }
    }
    
    private var chartSection: some View {
        ZStack {
            if viewModel.chartData.isEmpty {
                Text("Veri Yok")
                    .foregroundColor(.secondary)
            } else {
                Chart(viewModel.chartData) { item in
                    SectorMark(
                        angle: .value("Tutar", item.value),
                        innerRadius: .ratio(0.65),
                        angularInset: 2
                    )
                    .cornerRadius(8)
                    .foregroundStyle(item.color)
                    .opacity(viewModel.selectedCategory != nil && viewModel.selectedCategory != item ? 0.3 : 1.0)
                }
                .chartBackground { proxy in
                    GeometryReader { geo in
                        if let selected = viewModel.selectedCategory {
                            VStack(spacing: 4) {
                                Text(selected.category)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(selected.value.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                        } else {
                            VStack(spacing: 4) {
                                Text("Toplam")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(viewModel.totalExpense.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                }
                .frame(height: 250)
                .scaleEffect(animateChart ? 1 : 0.8)
                .opacity(animateChart ? 1 : 0)
                .onAppear { withAnimation(.spring()) { animateChart = true } }
            }
        }
        .padding(.horizontal)
    }
    
    private var listSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Kategori Detayları")
                .font(.headline)
                .padding(.horizontal)
                .padding(.bottom, 10)
            
            LazyVStack(spacing: 0) {
                ForEach(viewModel.chartData) { item in
                    CategoryRowView(item: item, viewModel: viewModel)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 5)
            .padding(.horizontal)
        }
    }
}

struct CategoryRowView: View {
    let item: AnalyticsViewModel.CategoryDouble
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var isSelected: Bool {
        viewModel.selectedCategory == item
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation {
                    if isSelected {
                        viewModel.selectedCategory = nil
                    } else {
                        viewModel.selectedCategory = item
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(item.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(String(item.category.prefix(1)))
                                .font(.headline)
                                .foregroundColor(item.color)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.category)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        ProgressView(value: item.percentage, total: 100)
                            .tint(item.color)
                            .scaleEffect(y: 4, anchor: .center)
                            .clipShape(Capsule())
                            .frame(height: 4)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.value.formatted(.currency(code: "TRY")))
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.primary)
                        Text("%\(String(format: "%.1f", item.percentage))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(isSelected ? Color.gray.opacity(0.05) : Color.clear)
            }
            
            if isSelected {
                drillDownView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Divider().padding(.leading, 64)
        }
    }
    
    private var drillDownView: some View {
        VStack(spacing: 0) {
            Divider()
            ForEach(viewModel.transactionsForSelectedCategory.prefix(5)) { transaction in
                HStack {
                    Text(transaction.note ?? "Harcama")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(transaction.date.formatted(date: .numeric, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(transaction.amount.formatted(.currency(code: "TRY")))
                        .font(.caption)
                        .bold()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                Divider().padding(.leading, 24)
            }
        }
    }
}

struct HistoryTrendView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Gider Geçmişi")
                    .font(.headline)
                    .padding(.horizontal)
                
                if viewModel.trendData.isEmpty {
                    ContentUnavailableView("Veri Yok", systemImage: "chart.xyaxis.line")
                         .frame(height: 250)
                } else {
                    Chart(viewModel.trendData) { item in
                        AreaMark(
                            x: .value("Tarih", item.date, unit: viewModel.selectedTimeRange == .year || viewModel.selectedTimeRange == .all ? .month : .day),
                            y: .value("Tutar", item.value)
                        )
                        .foregroundStyle(LinearGradient(colors: [.red.opacity(0.4), .red.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Tarih", item.date, unit: viewModel.selectedTimeRange == .year || viewModel.selectedTimeRange == .all ? .month : .day),
                            y: .value("Tutar", item.value)
                        )
                        .foregroundStyle(.red)
                        .interpolationMethod(.catmullRom)
                        .symbol(.circle)
                    }
                    .frame(height: 300)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.04), radius: 5)
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .padding(10)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 5)
    }
}


struct QuickAccessCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline) // Smaller icon
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption) // Smaller text
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70) // Reduced height as requested
        .padding(8) // Reduced internal padding
        .background(Color(.secondarySystemGroupedBackground)) // Kept as requested previously
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 5)
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(WalletManager.shared)
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

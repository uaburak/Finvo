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

// MARK: - Bento Grid Components

struct OverviewView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @EnvironmentObject var walletManager: WalletManager
    
    // Grid Configuration
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // 1. Full Width: Income vs Expense (Visual)
            IncomeExpenseBento(viewModel: viewModel)
            
            // 2. Full Width: Trend Chart
            TrendBento(viewModel: viewModel)
            
            // 3. Grid Row: Top Category & Quick Stats
            LazyVGrid(columns: columns, spacing: 16) {
                TopCategoryBento(viewModel: viewModel)
                StatsBento(viewModel: viewModel)
            }
            .padding(.horizontal)
            
            // 4. Full Width: Category Distribution
            CategoryChartBento(viewModel: viewModel)
            
            // 5. Member Comparison (Shared only)
            if let wallet = walletManager.selectedWallet, wallet.members.count > 1 {
                MemberComparisonBento(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Bento Components

struct BentoCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct IncomeExpenseBento: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        BentoCard {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Label("Gelir / Gider", systemImage: "arrow.left.arrow.right")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                
                // Content
                HStack(spacing: 20) {
                    // Income
                    VStack(alignment: .leading) {
                        Text("Gelir")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.totalIncome.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                            .font(.title3)
                            .bold()
                            .foregroundStyle(.green)
                    }
                    
                    Spacer()
                    
                    // Circular Ratio
                    ZStack {
                        Circle()
                            .stroke(Color.red.opacity(0.2), lineWidth: 8)
                            .frame(width: 60, height: 60)
                        
                        if viewModel.totalIncome + viewModel.totalExpense > 0 {
                            let ratio = viewModel.totalIncome / (viewModel.totalIncome + viewModel.totalExpense)
                            Circle()
                                .trim(from: 0, to: ratio)
                                .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 60, height: 60)
                        }
                    }
                    
                    Spacer()
                    
                    // Expense
                    VStack(alignment: .trailing) {
                        Text("Gider")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.totalExpense.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                            .font(.title3)
                            .bold()
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct TrendBento: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Harcama Trendi", systemImage: "chart.xyaxis.line")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    
                    if viewModel.isExpenseIncreased {
                        Label("Artış", systemImage: "arrow.up.right")
                            .font(.caption)
                            .padding(6)
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    } else {
                        Label("Düşüş", systemImage: "arrow.down.right")
                            .font(.caption)
                            .padding(6)
                            .background(Color.green.opacity(0.1))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
                
                if viewModel.trendData.isEmpty {
                    ContentUnavailableView("Veri Yok", systemImage: "chart.xyaxis.line")
                        .frame(height: 150)
                } else {
                    Chart(viewModel.trendData) { item in
                        AreaMark(
                            x: .value("Tarih", item.date, unit: viewModel.selectedTimeRange == .year || viewModel.selectedTimeRange == .all ? .month : .day),
                            y: .value("Tutar", item.value)
                        )
                        .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.3), .blue.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Tarih", item.date, unit: viewModel.selectedTimeRange == .year || viewModel.selectedTimeRange == .all ? .month : .day),
                            y: .value("Tutar", item.value)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                    }
                    .chartYAxis(.hidden)
                    .frame(height: 180)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct TopCategoryBento: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Zirve", systemImage: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                
                if let topCategoryName = viewModel.topCategoryName,
                   let category = viewModel.chartData.first(where: { $0.category == topCategoryName }) {
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.category)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(category.value.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    ProgressView(value: category.percentage, total: 100)
                        .tint(category.color)
                        .clipShape(Capsule())
                } else {
                    Text("-")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct StatsBento: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Günlük Ort.", systemImage: "calendar.badge.clock")
                    .font(.caption)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.averageDailySetting.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                        .font(.headline)
                    
                    Text("Ortalama")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct CategoryChartBento: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedSlice: AnalyticsViewModel.CategoryDouble?
    
    var body: some View {
        BentoCard {
            VStack(spacing: 20) {
                HStack {
                    Label("Dağılım", systemImage: "chart.pie.fill")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                
                HStack {
                    // Chart
                    Chart(viewModel.chartData.prefix(5)) { item in
                        SectorMark(
                            angle: .value("Tutar", item.value),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .cornerRadius(6)
                        .foregroundStyle(item.color)
                    }
                    .frame(width: 120, height: 120)
                    
                    Spacer()
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.chartData.prefix(4)) { item in
                            HStack {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 8, height: 8)
                                Text(item.category)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text("%\(Int(item.percentage))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if viewModel.chartData.count > 4 {
                            Text("+ \(viewModel.chartData.count - 4) Diğer")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 12)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Drill down button
                NavigationLink(destination: CategoriesBreakdownView(viewModel: viewModel)) {
                    Text("Tüm Detayları Gör")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct MemberComparisonBento: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("Üye Harcamaları", systemImage: "person.2.fill")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Chart(viewModel.memberData) { item in
                    BarMark(
                        x: .value("Tutar", item.value),
                        y: .value("Üye", item.username)
                    )
                    .foregroundStyle(item.color.gradient)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text(item.value.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: CGFloat(viewModel.memberData.count * 40 + 20))
            }
        }
        .padding(.horizontal)
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

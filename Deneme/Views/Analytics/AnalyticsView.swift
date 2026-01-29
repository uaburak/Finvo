import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @EnvironmentObject var walletManager: WalletManager
    @State private var selectedStackIndex = 0
    @Namespace private var namespace
    
    // Grid Config
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Time Picker (Floating Capsule)
                    timePicker
                    
                    if walletManager.selectedWallet == nil {
                        ContentUnavailableView("Cüzdan Seçilmedi", systemImage: "wallet.pass")
                            .padding(.top, 40)
                    } else {
                        // 2. Smart Stack (Net Worth / Pulse)
                        AnalyticsSmartStack(viewModel: viewModel, selectedIndex: $selectedStackIndex)
                            .frame(height: 140)
                            .padding(.horizontal)
                        
                        // 3. Bento Grid Layout
                        VStack(spacing: 12) {
                            // Row 1: Trend (Full Width)
                            TrendBento(viewModel: viewModel)
                            
                            // Row 2: Category Mix (Donut) & Top Category (Hero)
                            HStack(spacing: 12) {
                                CategoryChartBento(viewModel: viewModel)
                                    .frame(height: 180)
                                TopCategoryBento(viewModel: viewModel)
                                    .frame(height: 180)
                            }
                            
                            // Row 3: Daily Average & Quick Access (Categories)
                            HStack(spacing: 12) {
                                StatsBento(viewModel: viewModel)
                                    .frame(height: 140)
                                
                                NavigationLink(destination: CategoriesBreakdownView(viewModel: viewModel)) {
                                    QuickLinkBento(title: "Kategoriler", icon: "list.bullet.circle.fill", color: .orange)
                                }
                                .frame(height: 140)
                            }
                            
                            // Row 4: Member Comparison & Social Analytics (Shared only)
                            if let wallet = walletManager.selectedWallet, wallet.members.count > 1 {
                                VStack(spacing: 20) {
                                    // 1. Total Spending Comparison
                                    MemberComparisonBento(viewModel: viewModel)
                                    
                                    // 2. Persona Cards (Fun Titles)
                                    PersonaSliderView(viewModel: viewModel)
                                    
                                    // 3. Detailed Category Comparisons (Link)
                                    NavigationLink(destination: CategoryComparisonDetailView(viewModel: viewModel)) {
                                        ComparisonSummaryCard()
                                            .frame(height: 140)
                                    }
                                }
                            }
                            
                            // Row 5: Reports Link (Full Width Button style)
                            NavigationLink(destination: ReportsListView().environmentObject(walletManager)) {
                                HStack {
                                    Label("Detaylı Raporlar", systemImage: "doc.text.fill")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Analiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
                 AnalyticsShareSheet(activityItems: [item.url])
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
    
    // MARK: - Components
    
    private var timePicker: some View {
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
                                    .fill(Color.blue)
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
        .padding(.top, 10)
    }
    
    private func fetchWalletData(_ wallet: Wallet) async {
        await viewModel.fetchData(for: wallet)
    }
    
    private func exportWalletData(walletId: String) async {
        viewModel.exportItem = await viewModel.createExportFile(walletId: walletId)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(24)
            // No shadow for minimal look
    }
}

struct QuickLinkBento: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 12)
                
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("İncele")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TrendBento: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundColor(.blue)
                    Text("Trend")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    if !viewModel.trendData.isEmpty {
                         Text(viewModel.isExpenseIncreased ? "Artış" : "Düşüş")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(viewModel.isExpenseIncreased ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                            .foregroundColor(viewModel.isExpenseIncreased ? .red : .green)
                            .cornerRadius(4)
                    }
                }
                .padding(.bottom, 12)
                
                if viewModel.trendData.isEmpty {
                     Spacer()
                     Text("Veri Yok")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                     Spacer()
                } else {
                     Chart(viewModel.trendData) { item in
                         AreaMark(
                             x: .value("Tarih", item.date, unit: viewModel.selectedTimeRange == .year || viewModel.selectedTimeRange == .all ? .month : .day),
                             y: .value("Tutar", item.value)
                         )
                         .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                         .interpolationMethod(.catmullRom)
                         
                         LineMark(
                             x: .value("Tarih", item.date, unit: viewModel.selectedTimeRange == .year || viewModel.selectedTimeRange == .all ? .month : .day),
                             y: .value("Tutar", item.value)
                         )
                         .foregroundStyle(.blue)
                         .interpolationMethod(.catmullRom)
                         .lineStyle(StrokeStyle(lineWidth: 2))
                     }
                     .chartYAxis(.hidden)
                     .chartXAxis(.hidden)
                     .frame(height: 120)
                }
            }
        }
    }
}

struct CategoryChartBento: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .foregroundColor(.purple)
                    Text("Dağılım")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.bottom, 12)
                
                if viewModel.chartData.isEmpty {
                    Spacer()
                    Text("-")
                        .font(.headline)
                    Spacer()
                } else {
                    Spacer()
                    // Minimal Chart
                    Chart(viewModel.chartData.prefix(4)) { item in
                        SectorMark(
                            angle: .value("Tutar", item.value),
                            innerRadius: .ratio(0.6),
                            angularInset: 1
                        )
                        .cornerRadius(3)
                        .foregroundStyle(item.color)
                    }
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
            }
        }
    }
}

struct TopCategoryBento: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.orange)
                    Text("Zirve")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.bottom, 12)
                
                if let topCategoryName = viewModel.topCategoryName,
                   let category = viewModel.chartData.first(where: { $0.category == topCategoryName }) {
                    
                    Spacer()
                    // Hero Value
                    Text(category.value.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.8)
                    
                    Text(category.category)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    // Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.systemGray5)).frame(height: 4)
                            Capsule().fill(category.color).frame(width: geo.size.width * CGFloat(category.percentage / 100), height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                } else {
                    Spacer()
                    Text("-")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }
}

struct StatsBento: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text("Günlük")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.bottom, 12)
                
                Spacer()
                
                Text(viewModel.averageDailySetting.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Ortalama")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
}

struct MemberComparisonBento: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.indigo)
                    Text("Üyeler")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.bottom, 12)
                
                Chart(viewModel.memberData) { item in
                    BarMark(
                        x: .value("Tutar", item.value),
                        y: .value("Üye", item.username)
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text(item.value.formatted(.number.notation(.compactName)))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis { AxisMarks { _ in AxisValueLabel().font(.caption2) } }
                .frame(height: max(60, CGFloat(viewModel.memberData.count * 30)))
            }
        }
    }
}

// MARK: - Restored Subviews

struct AnalyticsShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct CategoriesBreakdownView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var animateChart = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                 // Interactive Donut Chart
                chartSection
                    .padding(.top, 20)
                
                // Interactive List
                listSection
            }
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Kategori Detayları")
        .navigationBarTitleDisplayMode(.inline)
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
            LazyVStack(spacing: 12) {
                ForEach(viewModel.chartData) { item in
                    CategoryRowView(item: item, viewModel: viewModel)
                }
            }
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
                 // Expanded / Collapsed Toggle
                withAnimation {
                    if isSelected {
                        viewModel.selectedCategory = nil
                    } else {
                        viewModel.selectedCategory = item
                    }
                }
            } label: {
                HStack(spacing: 16) {
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
                            .scaleEffect(y: 2, anchor: .center)
                            .clipShape(Capsule())
                            .frame(height: 4)
                            .frame(width: 80)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.value.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.primary)
                        Text("%\(String(format: "%.1f", item.percentage))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(20)
            }
            
            if isSelected {
                drillDownView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
    }
    
    private var drillDownView: some View {
        VStack(spacing: 8) {
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
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground).opacity(0.5))
                .cornerRadius(12)
                .padding(.horizontal, 24)
            }
        }
    }
}

import SwiftUI

struct BudgetDashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var tabManager: TabManager
    @State private var selectedWidgetIndex = 0
    
    var body: some View {
        VStack(spacing: 12) { // Tighter spacing for bento grid feel

            

            
            // 1. Asset & Savings Summary Slider (Vertical Smart Stack Style)
            DashboardSmartStack(viewModel: viewModel, selectedIndex: $selectedWidgetIndex)
                .frame(height: 140)
                .padding(.horizontal) // Add horizontal padding for the container
                .padding(.top, 10) // Restore positive spacing

            
            // 1.5. Income & Expense Quick Summary
            HStack(spacing: 12) {
                // Income Card
                NavigationLink(destination: TransactionListView(initialFilter: .income)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "arrow.down.left")
                                .font(.headline)
                                .foregroundColor(.green)
                            Spacer()
                            Text("Gelir")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(viewModel.monthlyIncome.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.04), radius: 5)
                }
                
                // Expense Card
                NavigationLink(destination: TransactionListView(initialFilter: .expense)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "arrow.up.right")
                                .font(.headline)
                                .foregroundColor(.red)
                            Spacer()
                            Text("Gider")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(viewModel.monthlyExpense.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.04), radius: 5)
                }
            }
            .padding(.horizontal)
            
            // 2. Quick Actions Slider (Horizontal)
            QuickActionsSlider(viewModel: viewModel)
                .frame(height: 100)
            
            // 3. Summary & Analytics (Bento Layout)
            VStack(spacing: 12) {
                // Row 1: Recent Transactions (Full Width)
                CompactRecentTransactionsCard(viewModel: viewModel)
                
                // Row 2: Budget Progress & Top Spending
                HStack(spacing: 12) {
                    NavigationLink(destination: SpendingLimitDetailView(viewModel: viewModel)) {
                        BudgetProgressCard(viewModel: viewModel)
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                    }
                    
                    NavigationLink(destination: TopSpendingDetailView(viewModel: viewModel)) {
                        TopCategoriesCard(viewModel: viewModel)
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                    }
                }
                
                // Row 3: Upcoming Payments & Financial Tip
                HStack(spacing: 12) {
                    NavigationLink(destination: UpcomingPaymentsDetailView(viewModel: viewModel)) {
                        UpcomingPaymentsCard(viewModel: viewModel)
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                    }
                    
                    NavigationLink(destination: FinancialInsightsView(viewModel: viewModel)) {
                        FinancialTipCard(viewModel: viewModel)
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

// MARK: - Components

struct QuickActionsSlider: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.quickActions) { item in
                    
                    // Direct Navigation for All Items
                    if item.actionType == .debts {
                        NavigationLink(destination: DebtsDetailView(viewModel: AnalyticsViewModel(from: viewModel))) {
                            QuickActionSquare(icon: item.icon, label: item.label, color: item.color)
                        }
                    } else if item.actionType == .categories {
                        NavigationLink(destination: CategoryListView()) {
                            QuickActionSquare(icon: item.icon, label: item.label, color: item.color)
                        }
                    } else if item.actionType == .limit {
                        NavigationLink(destination: SpendingLimitDetailView(viewModel: viewModel)) {
                            QuickActionSquare(icon: item.icon, label: item.label, color: item.color)
                        }
                    } else if item.actionType == .wallets {
                        NavigationLink(destination: WalletManagementListView()) {
                            QuickActionSquare(icon: item.icon, label: item.label, color: item.color)
                        }
                    } else if item.actionType == .reports {
                        NavigationLink(destination: ReportsView()) {
                            QuickActionSquare(icon: item.icon, label: item.label, color: item.color)
                        }
                    } else if item.actionType == .subscriptions {
                        NavigationLink(destination: SubscriptionsView()) {
                            QuickActionSquare(icon: item.icon, label: item.label, color: item.color)
                        }
                    } else if item.actionType == .investments {
                        NavigationLink(destination: InvestmentsView()) {
                            QuickActionSquare(icon: item.icon, label: item.label, color: item.color)
                        }
                    } 
                    // Settings removed
                }
            }
            .padding(.horizontal)
        }
    }
}

struct QuickActionSquare: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28)) // Slightly larger icon since background is gone
                .foregroundColor(color)
                .frame(height: 40) // Maintain layout consistency
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(width: 80, height: 90) // Square-ish
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4)
    }
}

// 1. Budget Progress Card
struct BudgetProgressCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    // Derived properties
    var limit: Double {
        return viewModel.monthlyLimit ?? 0
    }
    
    var remaining: Double {
        guard limit > 0 else { return 0 }
        return max(0, limit - viewModel.monthlyExpense)
    }
    
    var progress: Double {
        guard limit > 0 else { return 0 }
        return min(viewModel.monthlyExpense / limit, 1.0)
    }
    
    var currentDayInfo: String {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())!
        let daysInMonth = range.count
        let currentDay = calendar.component(.day, from: Date())
        return "\(currentDay)/\(daysInMonth)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gauge.medium")
                    .foregroundColor(.purple)
                Text("Limit")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Text(currentDayInfo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 12)
            
            if viewModel.monthlyLimit == nil {
                Spacer()
                Text("Limit Belirle")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                Spacer()
                
                // Hero Value
                Text(remaining.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                    .font(.system(size: 24, weight: .bold)) // Uniform Hero Size
                    .foregroundColor(.primary)
                
                Text("Kalan Bütçe")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Minimal Progress
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(progress > 0.8 ? Color.red : Color.purple)
                            .frame(width: geo.size.width * CGFloat(progress), height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.top, 8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(24) // Softer corners
        // Removed broad shadow, keeping it clean or minimal if needed, relying on parent
    }
}

// 2. Top Spending Categories Card
struct TopCategoriesCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    // Mock logic: Derive from recent transactions or specific fetch
    // Real implementation would aggregate specific category sums
    var topCategories: [(name: String, amount: Double, color: Color)] {
        // Simple mock for UI demonstration using recent transactions
        // In prod, VM should provide `topExpenses: [CategoryStats]`
        let expenses = viewModel.recentTransactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses, by: { $0.categoryName })
        let sorted = grouped.map { (key, value) in
            (name: key, amount: value.reduce(0) { $0 + $1.amount }, color: getColor(for: key))
        }.sorted { $0.amount > $1.amount }.prefix(3)
        
        return Array(sorted)
    }
    
    func getColor(for name: String) -> Color {
        if let cat = DefaultCategories.defaults.first(where: { $0.name == name }) {
            return cat.color
        }
        return .gray
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("En Çok")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.bottom, 12)
            
            if topCategories.isEmpty {
                Spacer()
                Text("Veri Yok")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                let top = topCategories[0]
                
                Spacer()
                
                // Hero Value
                Text(top.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(top.name)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Minimal Footer (Just top category color bar)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(top.color)
                            .frame(width: geo.size.width * 0.7, height: 6) // Fake proportion for design
                    }
                }
                .frame(height: 6)
                .padding(.top, 8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(24)
    }
}

// 3. Upcoming Payments Card
struct UpcomingPaymentsCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var nextPayment: Debt? {
        // Show the earliest due date debt
        return viewModel.activeDebts.sorted(by: { $0.nextDueDate < $1.nextDueDate }).first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.orange)
                Text("Yakında")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                if let debt = nextPayment {
                    Text(debt.nextDueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 12)
            
            if let debt = nextPayment {
                Spacer()
                
                // Hero Value
                Text(debt.installmentAmount.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(debt.name)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                // Minimal Footer (Progress)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(Color.orange)
                            .frame(width: geo.size.width * (Double(debt.paidInstallments) / Double(debt.totalInstallments)), height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.top, 8)
                
            } else {
                Spacer()
                Text("Ödeme Yok")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(24)
    }
}

// 4. Financial Tip Card
struct FinancialTipCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("İpucu")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.bottom, 12)
            
            Spacer()
            
            // Hero Content (Text instead of number)
            Text(viewModel.savingsBalance > 0 ? "Harika gidiyorsun!" : "Tasarruf Zamanı")
                .font(.system(size: 20, weight: .bold)) // Slightly smaller for text
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text("Detayları İncele")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Minimal Footer (Arrow)
            HStack {
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 20))
            }
            .padding(.top, 0) // Align to bottom right naturally
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(24)
    }
}

// Re-using CompactRecentTransactionsCard from before
struct CompactRecentTransactionsCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Son İşlemler")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: TransactionListView()) {
                    Text("Tümü")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if viewModel.recentTransactions.isEmpty {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 50)
                } else {
                    Text("Henüz işlem yok.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentTransactions.prefix(3)) { transaction in
                        VStack(spacing: 0) {
                            ListItem(
                                icon: getIcon(for: transaction.categoryName),
                                iconColor: getColor(for: transaction.categoryName, type: transaction.type),
                                title: transaction.categoryName,
                                subtitle: transaction.note ?? transaction.subCategoryName,
                                value: transaction.formattedAmount,
                                valueColor: transaction.type == .income ? .green : .red,
                                secondaryInfo: transaction.date.formatted(date: .abbreviated, time: .shortened)
                            )
                            .padding(.vertical, 4)
                            
                            if transaction.id != viewModel.recentTransactions.prefix(3).last?.id {
                                Divider()
                                    .padding(.leading, 56) // Aligned with text start
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 5)
    }
    
    func getIcon(for categoryName: String) -> String {
        // Simple lookup in defaults
        if let category = DefaultCategories.defaults.first(where: { $0.name == categoryName }) {
            return category.icon
        }
        // Fallback for custom categories or misses
        return "circle.fill"
    }
    
    func getColor(for categoryName: String, type: TransactionType) -> Color {
        if let category = DefaultCategories.defaults.first(where: { $0.name == categoryName }) {
            return category.color
        }
        return type == .income ? .green : .red
    }
}

extension AnalyticsViewModel {
    convenience init(from dashboardVM: DashboardViewModel) {
        self.init()
        self.activeDebts = dashboardVM.activeDebts
        self.totalDebtRemaining = dashboardVM.totalDebtRemaining
        self.upcomingDebtPayment = dashboardVM.upcomingDebtPayment
    }
}

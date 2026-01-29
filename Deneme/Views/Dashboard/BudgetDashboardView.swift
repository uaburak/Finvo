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
                // Recent Transactions (Full Width)
                CompactRecentTransactionsCard(viewModel: viewModel)
                
                HStack(spacing: 12) {
                    // Mini Analytics (Cash Flow)
                    TopSpendingCard(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                    
                    // Future Widget (Placeholder for now, maybe Budget Status or recurring)
                    CompactBudgetStatusCard(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
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
    
    // 8 Actions
    let actions: [(icon: String, label: String, color: Color, action: String)] = [
        ("creditcard.fill", "Borçlar", .orange, "OpenDebts"),
        ("gauge.medium", "Limitler", .purple, "OpenSpendingLimit"),
        ("square.grid.2x2.fill", "Kategoriler", .blue, "OpenCategories"),
        ("wallet.pass.fill", "Cüzdanlar", .gray, "OpenWalletManagement"),
        ("chart.pie.fill", "Raporlar", .pink, "OpenReports"),
        ("arrow.triangle.2.circlepath", "Abonelik", .indigo, "OpenSubscriptions"),
        ("leaf.fill", "Yatırım", .green, "OpenInvestments"),
        ("gearshape.fill", "Ayarlar", .secondary, "OpenSettings")
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<actions.count, id: \.self) { index in
                    let item = actions[index]
                    
                    // Handle Navigation or Notification
                    if item.action == "OpenDebts" {
                        NavigationLink(destination: DebtsDetailView(viewModel: AnalyticsViewModel(from: viewModel))) {
                            QuickActionSquare(icon: item.icon, label: item.label, color: item.color)
                        }
                    } else if item.action == "OpenCategories" {
                        NavigationLink(destination: CategoryListView()) {
                            QuickActionSquare(icon: item.icon, label: item.label, color: item.color)
                        }
                    } else {
                        Button {
                            NotificationCenter.default.post(name: NSNotification.Name(item.action), object: nil)
                        } label: {
                            QuickActionSquare(icon: item.icon, label: item.label, color: item.color)
                        }
                    }
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

// Re-using TopSpendingCard and CompactRecentTransactionsCard from before, but kept inline or assumed context.
// Adding CompactBudgetStatusCard
struct CompactBudgetStatusCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "banknote")
                    .foregroundColor(.green)
                Spacer()
                Text("Bütçe Durumu")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Çok Yakında")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 5)
    }
}

struct TopSpendingCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        NavigationLink(destination: AnalyticsView()) { // Assuming AnalyticsView exists
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(.blue)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .font(.headline)
                .padding(.bottom, 4)
                
                Text("Nakit Akışı")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Mini Bar Chart Visualization
                HStack(alignment: .bottom, spacing: 8) {
                    // Income Bar
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.gradient)
                            .frame(width: 20, height: barHeight(value: viewModel.monthlyIncome, maxVal: max(viewModel.monthlyIncome, viewModel.monthlyExpense)))
                    }
                    
                    // Expense Bar
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red.gradient)
                            .frame(width: 20, height: barHeight(value: viewModel.monthlyExpense, maxVal: max(viewModel.monthlyIncome, viewModel.monthlyExpense)))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Net")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text((viewModel.monthlyIncome - viewModel.monthlyExpense).formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                            .font(.caption)
                            .bold()
                            .foregroundColor(viewModel.monthlyIncome >= viewModel.monthlyExpense ? .green : .red)
                    }
                    .padding(.leading, 8)
                }
                .frame(height: 60)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.04), radius: 5)
        }
    }
    
    func barHeight(value: Double, maxVal: Double) -> CGFloat {
        guard maxVal > 0 else { return 0 }
        return CGFloat(value / maxVal * 50)
    }
}

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

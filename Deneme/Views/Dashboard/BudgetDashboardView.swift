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
            
            // 2. Middle Row: Monthly Budget & Debt Status
            HStack(spacing: 12) {
                // Monthly Budget (Flexible)
                MonthlyBudgetCard(income: viewModel.monthlyIncome, expense: viewModel.monthlyExpense)
                    .frame(maxWidth: .infinity)
                
                // Debt Status (Flexible)
                // We reuse DebtDashboardCard but might need to adjust it to fit the grid if it's too wide.
                // For now, let's wrap it or modify it. 
                // DebtDashboardCard was designed full width. Let's create a compact version or use it as is if it fits.
                // To keep it "Bento", let's use a specialized compact card or adapt the existing one.
                // For this iteration, I will use DebtDashboardCard but ensure it adapts or I'll create a CompactDebtCard logic here.
                // Actually, the user asked for a Bento Grid, so equal sized boxes are preferred.
                
                CompactDebtCard(viewModel: viewModel)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .fixedSize(horizontal: false, vertical: true) // Ensure heights match if possible, or let them grow
            
            // 3. Recent Transactions (Full Width or Large Box)
            RecentTransactionsCard(viewModel: viewModel)
                .padding(.horizontal)
            
            Spacer()
        }
        // Removed .padding(.top) to fix the gap issue
    }
}

// Internal compact debt card for the grid
struct CompactDebtCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        NavigationLink(destination: DebtsDetailView(viewModel: AnalyticsViewModel(from: viewModel))) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "creditcard.trianglebadge.exclamationmark")
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    Text("\(viewModel.activeDebts.count)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Borçlar")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Kalan: \(viewModel.totalDebtRemaining.formatted(.currency(code: "TRY").precision(.fractionLength(0))))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
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

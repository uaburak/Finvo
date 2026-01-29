import SwiftUI

struct PersonaDetailView: View {
    let persona: MemberPersona
    @ObservedObject var viewModel: AnalyticsViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background - Clean minimalist standard background
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Minimal Header Section
                    VStack(spacing: 20) {
                        // Icon Container - Clean, no heavy blur/glow
                        Circle()
                            .fill(persona.badgeColor.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: persona.icon)
                                    .font(.system(size: 48))
                                    .foregroundColor(persona.badgeColor)
                            )
                            .padding(.top, 20)
                        
                        VStack(spacing: 6) {
                            Text(persona.title)
                                .font(.title) // Standard Title
                                .bold()
                                .foregroundColor(.primary)
                            
                            Text(persona.username) 
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Text(persona.description)
                                .font(.callout)
                                .foregroundColor(persona.badgeColor)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    // 2. Stat Card - Simple & Clean
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BU DÖNEMKİ ETKİ")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            Text(persona.keyStat)
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        
                        // Small trend indicator or decoration could go here, but kept minimal
                        Image(systemName: "chart.bar.fill")
                            .font(.title3)
                            .foregroundStyle(persona.badgeColor.opacity(0.8))
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // 3. Transactions List (Evidence)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("İşlemler (Kanıt)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 0) {
                            let transactions = getRelevantTransactions()
                            if transactions.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("Bu başlık altında detaylı işlem bulunamadı.")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                        .padding()
                                    Spacer()
                                }
                            } else {
                                let displayedTransactions = Array(transactions.prefix(20))
                                ForEach(displayedTransactions, id: \.id) { transaction in
                                    VStack(spacing: 0) {
                                        HStack {
                                            // Minimal Row
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(transaction.subCategoryName.isEmpty ? transaction.categoryName : transaction.subCategoryName)
                                                    .font(.body)
                                                    .lineLimit(1)
                                                
                                                Text(transaction.date.formatted(date: .numeric, time: .omitted))
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(transaction.amount.formatted(.currency(code: "TRY")))
                                                .font(.callout)
                                                .fontWeight(.semibold)
                                                .foregroundColor(transaction.type == .income ? .green : .primary)
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 14)
                                        
                                        if transaction.id != displayedTransactions.last?.id {
                                            Divider()
                                                .padding(.leading, 16)
                                        }
                                    }
                                    .background(Color(.secondarySystemGroupedBackground))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Helper to get transactions for this persona's win
    func getRelevantTransactions() -> [Transaction] {
        return viewModel.getTransactions(forMember: persona.userId, categories: persona.relatedCategories)
    }
}

import SwiftUI

struct MonthlyBudgetCard: View {
    // Placeholder for now, can be connected to real budget logic later
    var income: Double
    var expense: Double
    
    var progress: Double {
        guard income > 0 else { return 0 }
        return min(expense / income, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "chart.pie.fill")
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading) {
                    Text("Bütçe")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("%\(Int(progress * 100)) Harcandı")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(progress > 0.9 ? Color.red : Color.purple)
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            Text("Kalan: \((income - expense).formatted(.currency(code: "TRY").precision(.fractionLength(0))))")
                .font(.caption2)
                .bold()
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

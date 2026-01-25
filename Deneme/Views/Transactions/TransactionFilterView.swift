import SwiftUI

struct TransactionFilterView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var filter: TransactionFilter
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Tarih")) {
                    DatePicker("Başlangıç", selection: $filter.startDate, displayedComponents: .date)
                    DatePicker("Bitiş", selection: $filter.endDate, displayedComponents: .date)
                }
                
                Section(header: Text("Sıralama")) {
                    Picker("Sıralama", selection: $filter.sortOrder) {
                        Text("Yeniden Eskiye").tag(SortOrder.dateDescending)
                        Text("Eskiden Yeniye").tag(SortOrder.dateAscending)
                        Text("Tutar (Artan)").tag(SortOrder.amountAscending)
                        Text("Tutar (Azalan)").tag(SortOrder.amountDescending)
                    }
                }
                
                Section {
                    Button("Filtreleri Temizle", role: .destructive) {
                        filter = TransactionFilter() // Reset to default
                    }
                }
            }
            .navigationTitle("Filtrele & Sırala")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uygula") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Supporting Models
struct TransactionFilter: Equatable {
    var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    var endDate: Date = Date()
    var sortOrder: SortOrder = .dateDescending
    var transactionType: TransactionType? = nil // Handled by segmented control mostly, but can be here too
}

enum SortOrder: String, CaseIterable, Identifiable {
    case dateAscending
    case dateDescending
    case amountAscending
    case amountDescending
    
    var id: String { rawValue }
}

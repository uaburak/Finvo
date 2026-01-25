import SwiftUI

struct TestView: View {
    @State private var toggleState1 = true
    @State private var toggleState2 = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("İşlem Örneği (Swipe Actions Var)") {
                    // Example 1: Transaction (Expense)
                    ListItem(
                        icon: "gift.fill",
                        iconColor: .pink, 
                        title: "Gift",
                        subtitle: "Partner Expenses",
                        username: "burak",
                        isRecurring: false,
                        value: "₺1,500",
                        valueColor: .red,
                        secondaryInfo: "10 Ekim 2025"
                    )
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            print("Delete action")
                        } label: {
                            Image(systemName: "trash")
                        }
                        Button {
                            print("Edit action")
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .tint(.orange)
                    }
                    
                    // Example 2: Transaction (Recurring)
                    ListItem(
                        icon: "briefcase.fill",
                        iconColor: .green,
                        title: "Salary",
                        subtitle: "Monthly Income",
                        username: "şirket",
                        isRecurring: true, // New: Recurring Badge Check
                        value: "₺45,000",
                        valueColor: .green,
                        secondaryInfo: "15 Ekim 2025"
                    )
                    .swipeActions(edge: .leading) {
                         Button {
                             print("Star action")
                         } label: {
                             Image(systemName: "star")
                         }
                         .tint(.yellow)
                    }
                    
                    // Example 3: Small user expense
                    ListItem(
                        icon: "cup.and.saucer.fill",
                        iconColor: .orange,
                        title: "Kahve",
                        subtitle: "Gıda",
                        username: "ahmet",
                        isRecurring: false,
                        value: "₺120",
                        valueColor: .red,
                        secondaryInfo: "Bugün"
                    )
                }
                
                Section("Kategori Örneği (Toggle & Varsayılan)") {
                    // Example 3: Category with Toggle
                    ListItem(
                        icon: "cart.fill",
                        iconColor: .orange,
                        title: "Market (Görünür)",
                        subtitle: "Gıda & Mutfak", 
                        isOn: $toggleState1 // Toggle On
                    )
                    
                    ListItem(
                        icon: "eye.slash.fill",
                        iconColor: .gray,
                        title: "Gizli Kategori",
                        subtitle: "Diğer",
                        isOn: $toggleState2 // Toggle Off
                    )
                    
                    // Example 4: SubCategory (Normal)
                    ListItem(
                        icon: "carrot.fill",
                        iconColor: .orange,
                        title: "Manav",
                        subtitle: "Market > Manav"
                    )
                }
            }
            .listStyle(.plain)
            .navigationTitle("Test Ekranı (ListItem)")
        }
    }
}

#Preview {
    TestView()
}

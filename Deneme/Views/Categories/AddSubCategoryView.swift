import SwiftUI

struct AddSubCategoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var categoryManager: CategoryManager
    
    let category: Category
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "circle.fill"
    @State private var selectedColorHex: String = "#34C759"
    
    // Constants (Reused from AddEditCategoryView for consistency)
    let availableColors: [String] = [
        "#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#00C7BE", "#32ADE6",
        "#007AFF", "#5856D6", "#AF52DE", "#FF2D55", "#A2845E", "#8E8E93"
    ]
    
    let availableIcons: [String] = [
        "house.fill", "cart.fill", "car.fill", "bolt.fill", "gift.fill",
        "chart.line.uptrend.xyaxis", "banknote.fill", "briefcase.fill",
        "doc.text.fill", "figure.walk", "drop.fill", "flame.fill", "wifi",
        "phone.fill", "tv.fill", "fork.knife", "cup.and.saucer.fill",
        "cross.case.fill", "pills.fill", "graduationcap.fill", "book.fill",
        "bag.fill", "gamecontroller.fill", "airplane", "bed.double.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Alt Kategori Detayları") {
                    TextField("Alt Kategori Adı", text: $name)
                    
                    // Color Picker
                    VStack(alignment: .leading) {
                        Text("Renk")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(availableColors, id: \.self) { hex in
                                    Circle()
                                        .fill(Color(hex: hex) ?? .gray)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary, lineWidth: selectedColorHex == hex ? 2 : 0)
                                                .padding(-2)
                                        )
                                        .onTapGesture {
                                            selectedColorHex = hex
                                        }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Icon Picker
                    VStack(alignment: .leading) {
                        Text("İkon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DropdownIconPicker(selectedIcon: $selectedIcon, icons: availableIcons, colorHex: selectedColorHex)
                    }
                }
            }
            .navigationTitle("Alt Kategori Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ekle") {
                        save()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    func save() {
        let newSub = SubCategory(
            name: name,
            icon: selectedIcon,
            colorHex: selectedColorHex
        )
        
        categoryManager.addSubCategory(to: category, subCategory: newSub)
        dismiss()
    }
}

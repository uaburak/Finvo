import SwiftUI

struct AddEditCategoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var categoryManager: CategoryManager // Need to inject this
    
    let existingCategory: Category?
    let type: CategoryType
    
    // Form States
    @State private var name: String = ""
    @State private var selectedIcon: String = "circle.fill"
    @State private var selectedColorHex: String = "#34C759"
    @State private var subCategories: [SubCategory] = []
    
    // New SubCategory State
    @State private var newSubCategoryName: String = ""
    
    // Constants
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
    
    init(category: Category? = nil, type: CategoryType = .expense) {
        self.existingCategory = category
        self.type = category?.type ?? type
        _name = State(initialValue: category?.name ?? "")
        _selectedIcon = State(initialValue: category?.icon ?? availableIcons.first!)
        _selectedColorHex = State(initialValue: category?.colorHex ?? availableColors.first!)
        _subCategories = State(initialValue: category?.subCategories ?? [])
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Section: Category Details
                Section("Kategori Detayları") {
                    TextField("Kategori Adı", text: $name)
                    
                    // Color Picker Grid
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
                    
                    // Icon Picker Grid
                    VStack(alignment: .leading) {
                        Text("İkon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DropdownIconPicker(selectedIcon: $selectedIcon, icons: availableIcons, colorHex: selectedColorHex)
                    }
                }
                
                // Section: Sub Categories
                Section("Alt Kategoriler") {
                    ForEach(subCategories) { sub in
                        HStack {
                            Image(systemName: sub.icon)
                                .foregroundColor(Color(hex: sub.colorHex) ?? .gray)
                            Text(sub.name)
                            Spacer()
                            Button {
                                deleteSubCategory(sub)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Yeni Alt Kategori", text: $newSubCategoryName)
                        Button {
                            addSubCategory()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(newSubCategoryName.isEmpty ? .gray : .blue)
                        }
                        .disabled(newSubCategoryName.isEmpty)
                    }
                }
            }
            .navigationTitle(existingCategory == nil ? "Kategori Ekle" : "Kategori Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        save()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    func addSubCategory() {
        guard !newSubCategoryName.isEmpty else { return }
        
        // For simplicity, subcategory inherits main category color/icon by default or simple logic
        // User requested detailed main and sub categories, but for editing, we keep it simple for now.
        // Or we could add a mini modal for subcategory details.
        // Let's assume subcategory gets same color as main for now, or a shade.
        
        let newSub = SubCategory(
            name: newSubCategoryName,
            icon: "circle.fill", // Default simple icon
            colorHex: selectedColorHex
        )
        subCategories.append(newSub)
        newSubCategoryName = ""
    }
    
    func deleteSubCategory(_ sub: SubCategory) {
        if let index = subCategories.firstIndex(where: { $0.id == sub.id }) {
            subCategories.remove(at: index)
        }
    }
    
    func save() {
        let category = Category(
            id: existingCategory?.id ?? UUID(),
            name: name,
            icon: selectedIcon,
            colorHex: selectedColorHex,
            type: type,
            subCategories: subCategories,
            isVisible: existingCategory?.isVisible ?? true,
            isCustom: true // Edits make it custom effectively, or keep existing flag
        )
        
        if existingCategory != nil {
            print("Updating category: \(category.name)")
            // Call update
             categoryManager.updateCategory(category)
        } else {
            print("Adding category: \(category.name)")
            // Call add
             categoryManager.addCategory(category)
        }
        
        dismiss()
    }
}

// Simple Dropdown-style Icon Picker or Grid Helper
struct DropdownIconPicker: View {
    @Binding var selectedIcon: String
    let icons: [String]
    let colorHex: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: selectedIcon)
                        .font(.title2)
                        .foregroundColor(Color(hex: colorHex) ?? .primary)
                    Text(isExpanded ? "Kapat" : "Değiştir")
                        .font(.caption)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                    ForEach(icons, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .frame(width: 44, height: 44)
                            .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                            .foregroundColor(Color(hex: colorHex) ?? .primary)
                            .onTapGesture {
                                selectedIcon = icon
                                withAnimation {
                                    isExpanded = false
                                }
                            }
                    }
                }
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

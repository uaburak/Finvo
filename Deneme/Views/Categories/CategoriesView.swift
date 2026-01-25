import SwiftUI

struct CategoriesView: View {
    @StateObject private var categoryManager = CategoryManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var selectedType: CategoryType = .expense
    
    // Sheet State
    @State private var showAddSheet = false
    @State private var categoryToEdit: Category?
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                let filteredCategories = categoryManager.getCategories(type: selectedType).filter { category in
                    if searchText.isEmpty { return true }
                    return category.name.localizedCaseInsensitiveContains(searchText) ||
                           category.subCategories.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) })
                }
                
                if filteredCategories.isEmpty {
                    VStack {
                        Spacer()
                        ContentUnavailableView("Kategori Bulunamadı", systemImage: "list.bullet", description: Text("Bu kriterlere uygun kategori bulunamadı."))
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredCategories) { category in
                            ListItem(
                                icon: category.icon,
                                iconColor: category.color,
                                title: category.name,
                                subtitle: "\(category.subCategories.count) Alt Kategori"
                            )
                            .background(
                                NavigationLink(destination: SubCategoryListView(category: category)
                                                .environmentObject(categoryManager)) {
                                    EmptyView()
                                }
                                .opacity(0)
                            )
                            // Swipe actions for parent category
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if authManager.currentUserProfile?.isPro ?? false {
                                    Button(role: .destructive) {
                                        categoryManager.deleteCategory(category)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    
                                    Button {
                                        categoryToEdit = category
                                    } label: {
                                        Image(systemName: "pencil")
                                    }
                                    .tint(.orange)
                                    
                                    Button {
                                        categoryManager.toggleVisibility(for: category)
                                    } label: {
                                        Image(systemName: category.isVisible ? "eye.slash" : "eye")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Principal: Segmented Control
                ToolbarItem(placement: .principal) {
                    Picker("Kategori Tipi", selection: $selectedType) {
                        Text("Gider").tag(CategoryType.expense)
                        Text("Gelir").tag(CategoryType.income)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                
                // Trailing: Add Button (Pro)
                ToolbarItem(placement: .topBarTrailing) {
                    if authManager.currentUserProfile?.isPro ?? false {
                        Button {
                            showAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Ara")
            .background(Color(UIColor.systemGroupedBackground))
            .sheet(isPresented: $showAddSheet) {
                AddEditCategoryView(type: selectedType)
                    .environmentObject(categoryManager)
            }
            .sheet(item: $categoryToEdit) { category in
                AddEditCategoryView(category: category)
                    .environmentObject(categoryManager)
            }
        }
    }
}

#Preview {
    CategoriesView()
}

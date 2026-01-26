import SwiftUI

struct SubCategoryListView: View {
    let category: Category
    @EnvironmentObject var categoryManager: CategoryManager
    @EnvironmentObject var tabManager: TabManager
    
    @State private var showAddSheet = false
    @State private var showProAlert = false
    
    var body: some View {
        List {
            Section {
                ForEach(category.subCategories as [SubCategory], id: \.id) { subCategory in
                    ListItem(
                        icon: subCategory.icon,
                        iconColor: subCategory.color,
                        title: subCategory.name,
                        subtitle: "Görünürlük",
                        isOn: Binding(
                            get: { subCategory.isVisible },
                            set: { _ in
                                categoryManager.toggleSubCategoryVisibility(category: category, subCategory: subCategory)
                            }
                        )
                    )
                }
            } header: {
                Text("Alt Kategoriler")
            } footer: {
                Text("Kapalı olan alt kategoriler işlem ekleme ekranında görünmez.")
            }
        }
        .listStyle(.plain)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Ekle") {
                    if AuthenticationManager.shared.currentUserProfile?.isPro == true {
                        showAddSheet = true
                    } else {
                        showProAlert = true
                    }
                }
            }
        }
        .alert("Premium Özellik", isPresented: $showProAlert) {
            Button("Pro Ol", role: .none) {
                tabManager.selectedTab = TabManager.settings
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Yeni alt kategori eklemek için Pro üye olmanız gerekmektedir.")
        }
        .sheet(isPresented: $showAddSheet) {
            AddSubCategoryView(category: category)
                .environmentObject(categoryManager)
        }
    }
}

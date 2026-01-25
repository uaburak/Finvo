import SwiftUI

struct SubCategoryListView: View {
    let category: Category
    @EnvironmentObject var categoryManager: CategoryManager
    
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
    }
}

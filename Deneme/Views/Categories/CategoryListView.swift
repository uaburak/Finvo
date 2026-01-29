import SwiftUI

struct CategoryListView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            ForEach(DefaultCategories.defaults) { category in
                Section(header: Label(category.name, systemImage: category.icon)
                    .foregroundColor(category.color)) {
                    ForEach(category.subCategories) { sub in
                        HStack {
                            Image(systemName: sub.icon)
                                .foregroundColor(sub.color)
                            Text(sub.name)
                        }
                    }
                }
            }
        }
        .navigationTitle("Kategoriler")
        .navigationBarTitleDisplayMode(.inline)
    }
}

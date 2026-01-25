import Foundation
import SwiftUI
import Combine

class CategoryManager: ObservableObject {
    @Published var categories: [Category] = []
    
    // Singleton instance
    static let shared = CategoryManager()
    
    private init() {
        loadCategories()
    }
    
    func loadCategories() {
        // In a real app, this might load from Firestore or UserDefaults.
        // For now, we load defaults.
        // We could verify if we have stored data, if so use it, else use defaults.
        self.categories = DefaultCategories.defaults
    }
    
    func getCategories(type: CategoryType) -> [Category] {
        return categories.filter { $0.type == type }
    }
    
    // MARK: - CRUD Operations (Pro Features)
    
    func addCategory(_ category: Category) {
        categories.append(category)
    }
    
    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        }
    }
    
    func deleteCategory(_ category: Category) {
        categories.removeAll { $0.id == category.id }
    }
    
    func toggleVisibility(for category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            var updated = categories[index]
            updated.isVisible.toggle()
            categories[index] = updated
        }
    }
    
    func addSubCategory(to category: Category, subCategory: SubCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            var updated = categories[index]
            updated.subCategories.append(subCategory)
            categories[index] = updated
        }
    }
    
    func toggleSubCategoryVisibility(category: Category, subCategory: SubCategory) {
        if let catIndex = categories.firstIndex(where: { $0.id == category.id }),
           let subIndex = categories[catIndex].subCategories.firstIndex(where: { $0.id == subCategory.id }) {
            var updatedCat = categories[catIndex]
            var updatedSub = updatedCat.subCategories[subIndex]
            updatedSub.isVisible.toggle()
            updatedCat.subCategories[subIndex] = updatedSub
            categories[catIndex] = updatedCat
        }
    }
}

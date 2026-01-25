import SwiftUI

struct AddTransactionView: View {
    @StateObject private var viewModel = AddTransactionViewModel()
    @Environment(\.dismiss) var dismiss
    
    // We need a wallet ID to save the transaction to.
    // For now, we will pass a placeholder or inject it.
    // Ideally, this view is presented with a specific wallet context.
    var walletId: String 
    
    // Wizard Steps
    enum Step {
        case type
        case category
        case subCategory
        case details
    }
    
    @State private var currentStep: Step = .type
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                // Step Indicator (Optional)
                
                // Content
                switch currentStep {
                case .type:
                    TypeSelectionStep(selectedType: $viewModel.selectedType) {
                        currentStep = .category
                    }
                case .category:
                    CategorySelectionStep(
                        type: viewModel.selectedType,
                        selectedCategory: $viewModel.selectedCategory
                    ) {
                        currentStep = .subCategory
                    }
                case .subCategory:
                    SubCategorySelectionStep(
                        category: viewModel.selectedCategory,
                        selectedSubCategory: $viewModel.selectedSubCategory
                    ) {
                        currentStep = .details
                    }
                case .details:
                    TransactionDetailsStep(viewModel: viewModel, walletId: walletId)
                }
            }
            .navigationTitle("İşlem Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                if currentStep != .type {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                           goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
            }
            .onChange(of: viewModel.isSuccess) {
                if viewModel.isSuccess {
                    dismiss()
                }
            }
        }
    }
    
    private func goBack() {
        switch currentStep {
        case .type: break
        case .category: currentStep = .type
        case .subCategory: currentStep = .category
        case .details: currentStep = .subCategory
        }
    }
}

// MARK: - Step 1: Type Selection
struct TypeSelectionStep: View {
    @Binding var selectedType: TransactionType
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Ne işlemi yapıyorsunuz?")
                .font(.title2)
                .padding()
            
            HStack(spacing: 20) {
                Button(action: {
                    selectedType = .expense
                    onNext()
                }) {
                    VStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.red)
                        Text("Gider")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Button(action: {
                    selectedType = .income
                    onNext()
                }) {
                    VStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.green)
                        Text("Gelir")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()
            
            Spacer()
        }
    }
}

// MARK: - Step 2: Category Selection
struct CategorySelectionStep: View {
    let type: TransactionType
    @Binding var selectedCategory: Category?
    var onNext: () -> Void
    @StateObject private var categoryManager = CategoryManager.shared
    
    var categories: [Category] {
        let categoryType: CategoryType = (type == .income) ? .income : .expense
        return categoryManager.getCategories(type: categoryType).filter { $0.isVisible }
    }
    
    // Grid Columns
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(categories) { category in
                    Button(action: {
                        selectedCategory = category
                        onNext()
                    }) {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: category.colorHex)?.opacity(0.2) ?? Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: category.icon)
                                    .font(.title2)
                                    .foregroundColor(Color(hex: category.colorHex) ?? .gray)
                            }
                            
                            Text(category.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Step 3: Any SubCategory
struct SubCategorySelectionStep: View {
    let category: Category?
    @Binding var selectedSubCategory: String?
    var onNext: () -> Void
    
    var body: some View {
        List {
            if let category = category {
                ForEach(category.subCategories.filter { $0.isVisible }) { sub in
                    Button {
                        selectedSubCategory = sub.name
                        onNext()
                    } label: {
                        HStack {
                            Image(systemName: sub.icon)
                                .foregroundColor(Color(hex: sub.colorHex) ?? .primary)
                            Text(sub.name)
                                .foregroundColor(.primary)
                        }
                    }
                }
            } else {
                Text("Kategori seçilmedi")
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Step 4: Details
struct TransactionDetailsStep: View {
    @ObservedObject var viewModel: AddTransactionViewModel
    var walletId: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Display Selected Info
                HStack {
                    if let category = viewModel.selectedCategory {
                        Image(systemName: category.icon)
                            .foregroundColor(Color(hex: category.colorHex) ?? .primary)
                        Text(category.name)
                        Text(">")
                            .foregroundColor(.gray)
                    }
                    if let sub = viewModel.selectedSubCategory {
                        Text(sub)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                // Amount Input
                TextField("0", text: $viewModel.amount)
                    .font(.system(size: 50, weight: .bold))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                
                Text(viewModel.selectedType == .income ? "Gelir Ekle" : "Gider Ekle")
                    .foregroundColor(viewModel.selectedType == .income ? .green : .red)
                
                Divider()
                
                // Note and Date
                VStack(spacing: 16) {
                    DatePicker("Tarih", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Not Ekle (Opsiyonel)", text: $viewModel.note)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Toggle("Tekrarlayan İşlem", isOn: $viewModel.isRecurring)
                }
                .padding()
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    Task {
                        await viewModel.saveTransaction(walletId: walletId)
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Kaydet")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .disabled(viewModel.isLoading)
            }
            .padding(.top, 20)
        }
    }
}

#Preview {
    AddTransactionView(walletId: "previewKey")
}

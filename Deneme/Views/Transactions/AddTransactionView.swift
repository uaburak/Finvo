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
                
                    VStack(spacing: 16) {
                        DatePicker("Tarih", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                        
                        TextField("Not Ekle (Opsiyonel)", text: $viewModel.note)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Toggle("Tekrarlayan İşlem (Abonelik)", isOn: $viewModel.isRecurring)
                        
                        if viewModel.isRecurring {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Tekrar Sıklığı")
                                    Spacer()
                                    Picker("Sıklık", selection: $viewModel.recurrenceFrequency) {
                                        ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                                            Text(freq.displayName).tag(freq)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                
                                DatePicker("Bitiş Tarihi (Opsiyonel)", selection: Binding(
                                    get: { viewModel.endDate ?? Date().addingTimeInterval(31536000) }, // Default +1 year visually but actually nil if not set? 
                                    // Better approach: Use a toggle for "Has End Date" or just optional binding magic.
                                    // For simplicity in SwiftUI forms, let's assume if they pick a date it's set.
                                    // But to allow NIL, we often need a separate toggle. 
                                    // Let's implement a clean "Set End Date" toggle wrapper.
                                    set: { viewModel.endDate = $0 }
                                ), displayedComponents: [.date])
                                .opacity(viewModel.endDate == nil ? 0.5 : 1)
                                .disabled(viewModel.endDate == nil)
                                .overlay(alignment: .leading) {
                                        Toggle("", isOn: Binding(
                                            get: { viewModel.endDate != nil },
                                            set: { if $0 { viewModel.endDate = Date().addingTimeInterval(2592000) } else { viewModel.endDate = nil } }
                                        )).labelsHidden()
                                }
                                
                                if viewModel.endDate == nil {
                                    Text("Süresiz tekrarlanır")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        Divider()
                        
                        Toggle("Borç Olarak İşle", isOn: $viewModel.isDebt)
                            .tint(.orange)
                        
                        if viewModel.isDebt {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Borç Detayları")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                TextField("Borç Adı (Örn: Kredi)", text: $viewModel.debtName)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                
                                HStack {
                                    Text("Tekrar Sıklığı")
                                    Spacer()
                                    Picker("Sıklık", selection: $viewModel.debtFrequency) {
                                        ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                                            Text(freq.displayName).tag(freq)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading) {
                                        Text("Toplam Taksit")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("12", text: $viewModel.totalInstallments)
                                            .keyboardType(.numberPad)
                                            .padding()
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text("Kaçıncı Taksit?")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("1", text: $viewModel.currentInstallment)
                                            .keyboardType(.numberPad)
                                            .padding()
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                            .transition(.scale.combined(with: .opacity))
                        }
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

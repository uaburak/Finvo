import SwiftUI
import FirebaseAuth

struct ExtendedOnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var authManager: AuthenticationManager
    
    // Step Control
    @State private var currentStep = 0
    let totalSteps = 4
    
    // Animations
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Steps Content
                    TabView(selection: $currentStep) {
                        profileStep
                            .tag(0)
                        walletStep
                            .tag(1)
                        limitsStep
                            .tag(2)
                        finishStep
                            .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never)) // Disable default dots
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                    
                    // Bottom Controls
                    VStack(spacing: 20) {
                        // Page Indicators
                        HStack(spacing: 8) {
                            ForEach(0..<totalSteps, id: \.self) { index in
                                Circle()
                                    .fill(index == currentStep ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .animation(.default, value: currentStep)
                            }
                        }
                        
                        // Continue Button
                        Button(action: nextStep) {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(currentStep == 3 ? "Başla" : "Devam Et")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                        }
                        .background(canProceed() ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .disabled(!canProceed() || viewModel.isLoading)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                    .padding(.top, 10)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation { currentStep -= 1 }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.body.bold())
                        }
                    }
                }
            }
        }
        // Pre-fill fields if needed
        .onAppear {
             if let authUser = Auth.auth().currentUser {
                 if viewModel.email.isEmpty {
                     viewModel.email = authUser.email ?? ""
                 }
                 if viewModel.displayName.isEmpty {
                     if let name = authUser.displayName {
                         viewModel.displayName = name
                     } else if let externalName = AuthenticationManager.shared.pendingExternalName {
                          viewModel.displayName = externalName
                     }
                 }
             }
        }
    }
    
    // MARK: - Step Title Logic
    var stepTitle: String {
        switch currentStep {
        case 0: return "Profilini Oluştur"
        case 1: return "Cüzdan Kurulumu"
        case 2: return "Hedefler"
        case 3: return "Tamamlandı"
        default: return ""
        }
    }
    
    // MARK: - Step Views
    
    var profileStep: some View {
        Form {
            Section(header: Text("Kullanıcı Bilgileri")) {
                // Email Field (Read-only)
                TextField("E-posta", text: $viewModel.email)
                    .disabled(true)
                    .foregroundColor(.gray)
                
                // Username Field
                HStack {
                    TextField("Kullanıcı Adı", text: $viewModel.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .onChange(of: viewModel.username) { oldValue, newValue in viewModel.checkUsernameUnique() }
                    
                    if viewModel.isCheckingUsername {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if let isAvailable = viewModel.isUsernameAvailable, !viewModel.username.isEmpty {
                        Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isAvailable ? .green : .red)
                    }
                }
                
                if let isAvailable = viewModel.isUsernameAvailable, !isAvailable, !viewModel.username.isEmpty {
                    Text("Bu kullanıcı adı alınmış.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                // Display Name Field
                TextField("Ad Soyad", text: $viewModel.displayName)
            }
            
            Section(header: Text("Kişisel")) {
                Picker("Cinsiyet", selection: $viewModel.gender) {
                    Text("Belirtmek İstemiyorum").tag("Belirtmek İstemiyorum")
                    Text("Erkek").tag("Erkek")
                    Text("Kadın").tag("Kadın")
                }
            }
        }
    }
    
    var walletStep: some View {
        Form {
            Section(header: Text("Cüzdan Bilgileri")) {
                TextField("Cüzdan Adı", text: $viewModel.walletName)
                
                Picker("Para Birimi", selection: $viewModel.currency) {
                    Text("Türk Lirası (₺)").tag("₺")
                    Text("ABD Doları ($)").tag("$")
                    Text("Euro (€)").tag("€")
                    Text("Sterlin (£)").tag("£")
                }
                
                Picker("Tür", selection: $viewModel.walletType) {
                    Text("Kişisel").tag(WalletType.personal)
                    Text("Paylaşımlı").tag(WalletType.shared)
                }
                
                Picker("Kategori", selection: $viewModel.walletContext) {
                    Text("Bütçe").tag(WalletContext.budget)
                    Text("Birikim").tag(WalletContext.savings)
                }
            }
            
            Section(header: Text("Başlangıç")) {
                HStack {
                    Text("Şu anki Bakiye")
                    Spacer()
                    TextField("0", text: $viewModel.initialBalance)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text(viewModel.currency)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    var limitsStep: some View {
        Form {
            Section(header: Text("Limitler (Opsiyonel)"), footer: Text("Kendine sınırlar koymak bütçeni yönetmeni kolaylaştırır.")) {
                HStack {
                    Text("Aylık Harcama Limiti")
                    Spacer()
                    TextField("Yok", text: $viewModel.spendingLimit)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text(viewModel.currency)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Birikim Hedefi")
                    Spacer()
                    TextField("Yok", text: $viewModel.savingsGoal)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text(viewModel.currency)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    var finishStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding()
            
            Text("Her Şey Hazır!")
                .font(.title2.bold())
            
            Text("Hesabın ve cüzdanın oluşturuldu.\nFinansal yolculuğuna başlamaya hazırsın.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Form {
                 Section {
                     Toggle("Bildirimleri Aç", isOn: $viewModel.isNotificationEnabled)
                 }
            }
            .frame(height: 100) // Small form just for toggle
            .scrollDisabled(true)
            
            Spacer()
        }
    }
    
    // MARK: - Logic
    
    func canProceed() -> Bool {
        switch currentStep {
        case 0:
            return viewModel.isUsernameAvailable == true && !viewModel.displayName.isEmpty
        case 1:
            return !viewModel.walletName.isEmpty
        case 2:
            return true // Optional
        case 3:
            return true
        default:
            return false
        }
    }
    
    func nextStep() {
        if currentStep == 0 {
            // Save Profile First
            Task {
                if await viewModel.saveUserProfile() {
                    withAnimation { currentStep += 1 }
                }
            }
        } else if currentStep == 1 {
             withAnimation { currentStep += 1 }
        } else if currentStep == 2 {
             // Create Wallet & Transaction & Set Limits
             Task {
                 if await viewModel.createInitialWallet() {
                     withAnimation { currentStep += 1 }
                     
                     // Also handle notifications here if enabled?
                     if viewModel.isNotificationEnabled {
                         do {
                             let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                             if granted {
                                 print("Notifications authorized")
                             }
                         } catch {
                             print("Notification permission error: \(error)")
                         }
                     }
                 }
             }
        } else if currentStep == 3 {
            // Finish -> Refresh User Profile in AuthManager to trigger main tab view
            Task {
                await authManager.fetchUserProfile()
                // Transition handled by ContentView state change based on authManager.isProfileComplete
            }
        }
    }
}

#Preview {
    ExtendedOnboardingView()
        .environmentObject(AuthenticationManager.shared)
}

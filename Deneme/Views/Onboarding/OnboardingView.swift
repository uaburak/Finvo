import SwiftUI

struct OnboardingView: View {
    @AppStorage("isOnboardingSeen") var isOnboardingSeen: Bool = false
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(
            image: "chart.bar.xaxis",
            title: "Harcamalarınızı Kontrol Edin",
            description: "Detaylı grafikler ve analizlerle paranızın nereye gittiğini tam olarak görün."
        ),
        OnboardingPage(
            image: "person.2.fill",
            title: "Ortak Cüzdanlar",
            description: "Aileniz, arkadaşlarınız veya ev arkadaşlarınızla ortak bütçeler oluşturun ve yönetin."
        ),
        OnboardingPage(
            image: "arrow.left.arrow.right",
            title: "Borç Alacak Takibi",
            description: "Kim kime ne kadar borçlu? Borçlarınızı ve alacaklarınızı kolayca takip edin."
        )
    ]
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        withAnimation {
                            isOnboardingSeen = true
                        }
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "İlerle" : "Başla")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: page.image)
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .foregroundColor(.blue)
                .padding()
            
            Text(page.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}

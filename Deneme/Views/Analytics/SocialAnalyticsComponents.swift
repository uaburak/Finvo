import SwiftUI

struct PersonaSliderView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Başarı Rozetleri", systemImage: "trophy.fill")
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.memberPersonas) { persona in
                        NavigationLink(destination: PersonaDetailView(persona: persona, viewModel: viewModel)) {
                            PersonaCardView(persona: persona)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

// Minimal Redesign
// Minimal Redesign (Matching Tip Card Style)
// Minimal Redesign (Centered)
struct PersonaCardView: View {
    let persona: MemberPersona
    
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            
            // Icon
            Image(systemName: persona.icon)
                .font(.system(size: 32)) // Prominent Icon
                .foregroundColor(persona.badgeColor)
            
            // Hero Content
            VStack(spacing: 4) {
                Text(persona.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Text(persona.username) // Real Name
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(12)
        .frame(width: 140, height: 140)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(24)
    }
}

import SwiftUI

struct PersonaSliderView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ekibin Rolleri", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.indigo)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.memberPersonas) { persona in
                        PersonaCardView(persona: persona)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

struct PersonaCardView: View {
    let persona: AnalyticsViewModel.MemberPersona
    
    var body: some View {
        VStack(spacing: 12) {
            // Minimal Avatar
            Circle()
                .fill(persona.color.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: persona.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(persona.color)
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
            
            VStack(spacing: 4) {
                Text(persona.username)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                // Fun Badge
                Text(persona.title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(persona.color.opacity(0.1))
                    .foregroundStyle(persona.color)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .frame(width: 110, height: 130)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        // No heavy shadows, just clean
    }
}

import SwiftUI

struct TagPill: View {
    let text: String
    var icon: String? = nil
    var color: Color = Color.appAccent
    var isSelected: Bool = true
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(AppFont.smallTag)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            isSelected ? color.opacity(0.15) : Color.white.opacity(0.05)
        )
        .foregroundStyle(isSelected ? color : Color.textMuted)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        HStack {
            TagPill(text: "IM Focus")
            TagPill(text: "Sprint", color: .positive)
            TagPill(text: "Inactive", isSelected: false)
        }
    }
}

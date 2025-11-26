import SwiftUI

struct MetricTile: View {
    let label: String
    let value: String
    var icon: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundStyle(Color.textMuted)
                }
                Text(label)
                    .font(AppFont.captionMuted)
                    .foregroundStyle(Color.textMuted)
            }
            
            Text(value)
                .font(AppFont.bodyBold)
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        HStack {
            MetricTile(label: "Avg Distance", value: "3,433 yds")
            MetricTile(label: "Total Time", value: "3h 20m")
        }
        .padding()
    }
}

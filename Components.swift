import SwiftUI


struct Card<Content: View>: View {
let content: Content
init(@ViewBuilder content: () -> Content) { self.content = content() }
var body: some View {
content
.padding(16)
.background(Color(.secondarySystemBackground))
.cornerRadius(16)
}
}


struct BarRow: View {
var label: String
var valueText: String
var fill: Double // 0...1
var tint: Color
var body: some View {
VStack(alignment: .leading, spacing: 6) {
HStack { Text(label).font(.subheadline); Spacer(); Text(valueText).font(.subheadline).bold() }
GeometryReader { geo in
ZStack(alignment: .leading) {
RoundedRectangle(cornerRadius: 8).fill(Color(.tertiarySystemFill))
RoundedRectangle(cornerRadius: 8)
.fill(tint)
.frame(width: max(4, geo.size.width * fill))
}
}
.frame(height: 10)
}
}
}

import SwiftUI

struct SwipeToDeleteCard<Content: View>: View {
    let onDelete: () -> Void
    let content: () -> Content

    @State private var offset: CGFloat = 0
    @GestureState private var drag: CGSize = .zero

    private let threshold: CGFloat = 80

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete background (only revealed when swiped)
            HStack {
                Spacer()
                Circle()
                    .fill(Color.red)
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "trash").foregroundColor(.white))
                    .padding(.trailing, 14)
            }

            // Your card content
            content()
                .offset(x: offset + drag.width)
                .gesture(
                    DragGesture()
                        .updating($drag) { value, state, _ in
                            // Only allow left swipe
                            state = CGSize(width: min(0, value.translation.width), height: 0)
                        }
                        .onEnded { value in
                            let total = offset + value.translation.width
                            if total < -threshold {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                    offset = -120
                                }
                                // Perform delete after the reveal animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    withAnimation(.easeInOut) {
                                        onDelete()
                                    }
                                }
                            } else {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                    offset = 0
                                }
                            }
                        }
                )
        }
        .contentShape(Rectangle())
    }
}


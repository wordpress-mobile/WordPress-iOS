import SwiftUI

struct PulseAnimationModifier: ViewModifier {
    @State private var opacity: Double = 0.5

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                ) {
                    opacity = 0.9
                }
            }
    }
}

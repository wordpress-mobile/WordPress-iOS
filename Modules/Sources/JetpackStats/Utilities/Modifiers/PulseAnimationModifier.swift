import SwiftUI

struct PulseAnimationModifier: ViewModifier {
    let isEnabled: Bool

    @State private var opacity: Double = 1

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onChange(of: isEnabled, initial: true) { _, isEnabled in
                withAnimation(isEnabled ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true) : nil) {
                    opacity = isEnabled ? 0.3 : 1
                }
            }
    }
}

extension View {
    func pulsating(_ isEnabled: Bool = true) -> some View {
        modifier(PulseAnimationModifier(isEnabled: isEnabled))
    }
}

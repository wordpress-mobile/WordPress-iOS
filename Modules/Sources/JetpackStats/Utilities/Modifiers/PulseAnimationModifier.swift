import SwiftUI

struct PulseAnimationModifier: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .mask {
                    PulsingMask()
                }
        } else {
            content
        }
    }
}

private struct PulsingMask: View {
    @State private var opacity: Double = 0.3

    var body: some View {
        Rectangle()
            .fill(.white)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    opacity = 1.0
                }
            }
    }
}

extension View {
    func pulsating(_ isEnabled: Bool = true) -> some View {
        modifier(PulseAnimationModifier(isEnabled: isEnabled))
    }
}

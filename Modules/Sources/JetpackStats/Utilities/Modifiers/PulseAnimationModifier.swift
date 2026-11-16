import SwiftUI

struct PulseAnimationModifier: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        // Always apply the mask, so toggling the pulse keeps the content's identity
        // (and lets a placeholder chart animate into the loaded one).
        content
            .mask {
                if isEnabled {
                    PulsingMask()
                } else {
                    Rectangle()
                }
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

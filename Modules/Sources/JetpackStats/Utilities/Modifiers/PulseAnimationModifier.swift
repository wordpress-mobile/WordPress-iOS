import SwiftUI

struct PulseAnimationModifier: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if isEnabled {
                    PulsingOverlay()
                        .padding(-8) // Temporary workaround to cover charts properly
                }
            }
    }
}

private struct PulsingOverlay: View {
    @State private var opacity: Double = 0.1

    var body: some View {
        Constants.Colors.secondaryBackground
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5) .repeatForever(autoreverses: true)) {
                    opacity = 0.6
                }
            }
            .allowsHitTesting(false)
    }
}

extension View {
    func pulsating(_ isEnabled: Bool = true) -> some View {
        modifier(PulseAnimationModifier(isEnabled: isEnabled))
    }
}
